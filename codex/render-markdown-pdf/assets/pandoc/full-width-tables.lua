-- Lua filter to keep tables full-width while assigning widths by content.
-- Explicit Pandoc widths are preserved proportionally; otherwise widths are
-- inferred from the header plus the first few body rows.

local MAX_SAMPLE_ROWS = 8
local MIN_WIDTH = 0.07
local MAX_WIDTH = 0.28

local SHORT_HEADER_KEYWORDS = {
  "ip",
  "ipv4",
  "ipv6",
  "port",
  "seq",
  "ack",
  "ttl",
  "mac",
  "id",
  "flag",
  "flags",
  "window",
  "win",
  "state",
  "status",
  "src",
  "dst",
  "源ip",
  "目的ip",
  "源端口",
  "目的端口",
  "端口",
  "窗口",
  "状态",
  "序号",
  "编号",
  "长度",
  "校验和"
}

local LONG_HEADER_KEYWORDS = {
  "备注",
  "说明",
  "描述",
  "分析",
  "details",
  "detail",
  "description",
  "remark",
  "remarks",
  "reason",
  "notes",
  "comment",
  "payload",
  "summary",
  "结果",
  "结论"
}

local function clamp(value, low, high)
  if value < low then
    return low
  end
  if value > high then
    return high
  end
  return value
end

local function normalize_space(text)
  if not text or text == "" then
    return ""
  end
  local normalized = text:gsub("%s+", " ")
  normalized = normalized:gsub("^%s+", "")
  normalized = normalized:gsub("%s+$", "")
  return normalized
end

local function visible_length(text)
  text = normalize_space(text)
  if text == "" then
    return 0
  end

  local ok, length = pcall(utf8.len, text)
  if ok and length then
    return length
  end

  return #text
end

local function stringify_cell(cell)
  return normalize_space(pandoc.utils.stringify(cell.contents))
end

local function contains_keyword(text, keywords)
  if text == "" then
    return false
  end

  local lowered = text:lower()
  for _, keyword in ipairs(keywords) do
    if lowered:find(keyword, 1, true) then
      return true
    end
  end

  return false
end

local function is_code_like_text(text)
  local compact = text:gsub("%s+", "")
  local length = visible_length(compact)

  if length == 0 or length > 32 then
    return false
  end

  return compact:match("^[%w%._:/%-]+$") ~= nil
end

local function is_long_text(text)
  local length = visible_length(text)

  if length >= 28 then
    return true
  end

  if length >= 16 and (text:find("%s") or text:find("[，。；：、（）()]")) then
    return true
  end

  return false
end

local function normalize_widths(widths)
  local total = 0
  for _, width in ipairs(widths) do
    total = total + math.max(width, 0)
  end

  if total <= 0 then
    local equal = 1 / #widths
    for i = 1, #widths do
      widths[i] = equal
    end
    return widths
  end

  for i = 1, #widths do
    widths[i] = math.max(widths[i], 0) / total
  end

  return widths
end

local function bounded_normalize(weights, min_width, max_width)
  local count = #weights
  if count == 0 then
    return {}
  end

  local effective_min = min_width
  local effective_max = max_width

  if effective_min * count > 1 then
    effective_min = 0
  end

  if effective_max * count < 1 then
    effective_max = 1
  end

  local widths = {}
  local free = {}
  local remaining = 1

  for i = 1, count do
    free[i] = true
  end

  while true do
    local weight_sum = 0
    local free_count = 0

    for i = 1, count do
      if free[i] then
        free_count = free_count + 1
        weight_sum = weight_sum + math.max(weights[i], 0)
      end
    end

    if free_count == 0 then
      break
    end

    if weight_sum <= 0 then
      local equal = remaining / free_count
      for i = 1, count do
        if free[i] then
          widths[i] = equal
        end
      end
    else
      for i = 1, count do
        if free[i] then
          widths[i] = remaining * math.max(weights[i], 0) / weight_sum
        end
      end
    end

    local changed = false
    local used = 0

    for i = 1, count do
      if free[i] then
        if widths[i] < effective_min then
          widths[i] = effective_min
          free[i] = false
          changed = true
        elseif widths[i] > effective_max then
          widths[i] = effective_max
          free[i] = false
          changed = true
        end
      end

      if not free[i] then
        used = used + widths[i]
      end
    end

    if not changed then
      break
    end

    remaining = 1 - used
    if remaining <= 0 then
      break
    end
  end

  local total = 0
  local unassigned = 0
  for i = 1, count do
    if widths[i] == nil then
      unassigned = unassigned + 1
    else
      total = total + widths[i]
    end
  end

  if unassigned > 0 then
    local equal = (1 - total) / unassigned
    for i = 1, count do
      if widths[i] == nil then
        widths[i] = equal
      end
    end
  end

  return normalize_widths(widths)
end

local function explicit_widths(tbl)
  local widths = {}
  local first_width = nil
  local all_equal = true

  for i, colspec in ipairs(tbl.colspecs) do
    local width = colspec[2]
    if type(width) ~= "number" or width <= 0 then
      return nil
    end

    if first_width == nil then
      first_width = width
    elseif math.abs(width - first_width) > 0.000001 then
      all_equal = false
    end

    widths[i] = width
  end

  -- Pandoc often auto-fills pipe tables with equal widths. Treat that as a
  -- generated default so heterogeneous tables can still use content-aware
  -- allocation. Preserve only meaningful non-equal ratios here.
  if #widths > 1 and all_equal then
    return nil
  end

  return normalize_widths(widths)
end

local function new_column_stats()
  return {
    header_text = "",
    sample_count = 0,
    total_length = 0,
    max_length = 0,
    code_like_count = 0,
    long_text_count = 0
  }
end

local function record_sample(stats, text, is_header)
  text = normalize_space(text)
  if text == "" then
    return
  end

  local length = visible_length(text)
  if is_header then
    if stats.header_text == "" then
      stats.header_text = text
    else
      stats.header_text = stats.header_text .. " " .. text
    end
  end

  stats.sample_count = stats.sample_count + 1
  stats.total_length = stats.total_length + length
  stats.max_length = math.max(stats.max_length, length)

  if is_code_like_text(text) then
    stats.code_like_count = stats.code_like_count + 1
  end

  if is_long_text(text) then
    stats.long_text_count = stats.long_text_count + 1
  end
end

local function sample_column_stats(tbl, num_cols)
  local columns = {}
  for i = 1, num_cols do
    columns[i] = new_column_stats()
  end

  if tbl.head and tbl.head.rows then
    for _, row in ipairs(tbl.head.rows) do
      for i = 1, num_cols do
        local cell = row.cells and row.cells[i]
        if cell then
          record_sample(columns[i], stringify_cell(cell), true)
        end
      end
    end
  end

  local sampled_body_rows = 0
  for _, body in ipairs(tbl.bodies or {}) do
    for _, row in ipairs(body.body or {}) do
      sampled_body_rows = sampled_body_rows + 1
      for i = 1, num_cols do
        local cell = row.cells and row.cells[i]
        if cell then
          record_sample(columns[i], stringify_cell(cell), false)
        end
      end

      if sampled_body_rows >= MAX_SAMPLE_ROWS then
        return columns
      end
    end
  end

  return columns
end

local function estimate_weight(stats)
  local header_length = visible_length(stats.header_text)
  local avg_length = 0
  local code_ratio = 0
  local long_ratio = 0

  if stats.sample_count > 0 then
    avg_length = stats.total_length / stats.sample_count
    code_ratio = stats.code_like_count / stats.sample_count
    long_ratio = stats.long_text_count / stats.sample_count
  else
    avg_length = header_length
  end

  local size_hint = math.max(header_length * 0.9, avg_length, stats.max_length * 0.55)

  if contains_keyword(stats.header_text, SHORT_HEADER_KEYWORDS)
      or (code_ratio >= 0.6 and stats.max_length <= 32) then
    return clamp(0.75 + size_hint / 32, 0.75, 1.25)
  end

  if contains_keyword(stats.header_text, LONG_HEADER_KEYWORDS)
      or long_ratio >= 0.35
      or avg_length >= 18
      or stats.max_length >= 32 then
    return clamp(1.8 + size_hint / 22, 1.8, 3.2)
  end

  return clamp(1.0 + size_hint / 20, 1.0, 1.8)
end

local function content_aware_widths(tbl)
  local num_cols = #tbl.colspecs
  local stats = sample_column_stats(tbl, num_cols)
  local weights = {}

  for i = 1, num_cols do
    weights[i] = estimate_weight(stats[i])
  end

  return bounded_normalize(weights, MIN_WIDTH, MAX_WIDTH)
end

function Table(tbl)
  local num_cols = #tbl.colspecs
  if num_cols == 0 then
    return tbl
  end

  local widths = explicit_widths(tbl)
  if not widths then
    widths = content_aware_widths(tbl)
  end

  for i = 1, num_cols do
    local align = tbl.colspecs[i][1]
    tbl.colspecs[i] = {align, widths[i]}
  end

  return tbl
end

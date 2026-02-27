-- Lua filter to force all tables to use full textwidth
-- by converting column specs to proportional widths

function Table(tbl)
  -- Get number of columns
  local num_cols = #tbl.colspecs
  
  if num_cols == 0 then
    return tbl
  end
  
  -- Calculate equal width for each column (proportional)
  local width = 1.0 / num_cols
  
  -- Replace all column specs with proportional width
  for i = 1, num_cols do
    local align = tbl.colspecs[i][1]  -- Keep original alignment
    tbl.colspecs[i] = {align, width}  -- Set proportional width
  end
  
  return tbl
end

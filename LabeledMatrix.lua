LabeledMatrix = {}
LabeledMatrix.__index = LabeledMatrix

setmetatable(LabeledMatrix, {
  __call = function (class, ...)
	local self = setmetatable({}, class)
    self:_new(...)
    return self
  end,
})

function LabeledMatrix: _new()
	
	-- self.data[row][col], 
	-- e.g. row: status variables, col: column_labels
	--  		(spell1)	(spell2)	(spell3)
	-- (mana) 	true 		true		false
	-- (cd ) 	1 			2			3
	
	self.data = {} 
	self.row_labels = {}
	self.column_labels = {}
	self.n_rows = 0
	self.n_columns = 0

	
	return self
end

function LabeledMatrix: printMatrix()
	if self.n_rows < 1 or self.n_columns < 1 then return nil end
	print("Row labels: "..self.n_rows)
	for i, v in ipairs(self.row_labels) do
		print(v)
	end 
	print("Column labels: "..self.n_columns)
	for i, v in ipairs(self.column_labels) do
		print(v)
	end 
	print("Data: ")
	for i = 1, self.n_rows do
		for j = 1, self.n_columns do
			print(self.data[i][j])
		end 
	end
end

function LabeledMatrix: getRowLabels()
	return self.n_rows, self.row_labels
end

function LabeledMatrix: getColumnLabels()
	return self.n_columns, self.column_labels
end

function LabeledMatrix: searchRow(row_label)
	if not self.row_labels then return nil end 
	local row 
	for i, v in ipairs(self.row_labels) do
		if v == row_label then row = i end
	end
	return row
end

function LabeledMatrix: searchColumn(column_label)
	
	if not self.column_labels then return nil end 

	local col 
	for i, v in ipairs(self.column_labels) do
		if v == column_label then col = i end
	end
	return col
end

function LabeledMatrix: addRow(row_labels)
	if not row_labels then return nil end
	if type(row_labels) ~= "table" then 
		local row_label_table = {}
		row_label_table[1] = row_labels
		row_labels = row_label_table
	end
	for i, v in ipairs(row_labels) do
		if not self:searchRow(v) then 
			self.n_rows = self.n_rows + 1
			self.row_labels[self.n_rows] = v
			self.data[self.n_rows] = {}
		end
	end
	return self.n_rows
end

function LabeledMatrix: addColumn(column_labels)
	if not column_labels then return nil end
	if type(column_labels) ~= "table" then 
		local column_label_table = {}
		column_label_table[1] = column_labels
		column_labels = column_label_table
	end
	for i, v in ipairs(column_labels) do
		if not self:searchColumn(v) then 
			self.n_columns = self.n_columns + 1
			self.column_labels[self.n_columns] = v
		end
	end
	return self.n_columns
end

function LabeledMatrix: update(row_label, column_label, value)
	local row, col = 0, 0
	if self.row_labels then
		for i, v in ipairs(self.row_labels) do
			if v == row_label then row = i end
		end
	end
	if self.column_labels then
		for i, v in ipairs(self.column_labels) do
			if v == column_label then col = i end
		end
	end
	if row == 0 then row = self:addRow(row_label) end
	if col == 0 then col = self:addColumn(column_label) end
	
	self.data[row][col] = value
	return value, row, col
end

function LabeledMatrix: get(row_label, column_label)
	if not self.row_labels then return nil end
	if not self.column_labels then return nil end
	
	local row, col = 0, 0

	for i, v in ipairs(self.row_labels) do
		if v == row_label then row = i end
	end
	
	for i, v in ipairs(self.column_labels) do
		if v == column_label then col = i end
	end 
	
	if row == 0 or col == 0 then
		return nil
	else
		return self.data[row][col]
	end
end

function LabeledMatrix: rowOr(row_label)
	local value
	local row = 0 
	for i, v in ipairs(self.row_labels) do
		if v == row_label then row = i end
	end
	if row == 0 then return nil end
	for i, _ in ipairs(self.column_labels) do 
		value = value or self.data[row][i]
	end
	return value
end
function obj = getSchema
persistent schemaObject
if isempty(schemaObject)
    schemaObject = dj.Schema(dj.conn, 'ephys', 'ephys');
end
obj = schemaObject;
end

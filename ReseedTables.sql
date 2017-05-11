
CREATE PROCEDURE ReseedTables AS
BEGIN

SELECT 'DECLARE @DynamicSQL varchar(max) 
SELECT @DynamicSQL = ''DBCC CHECKIDENT(''''' + s.name + '.' + t.name + ''''', reseed, '' + CAST(MAX(' + c.name + ') AS VARCHAR(50)) + '')'' FROM ' + s.name + '.' + t.name + ' 
EXECUTE( @DynamicSQL )' AS Commands
INTO #ReseedCommands
FROM sys.schemas AS s
INNER JOIN sys.tables AS t
  ON s.[schema_id] = t.[schema_id]
INNER JOIN sys.columns AS c
    ON c.[object_id] = t.[object_id]
WHERE c.is_identity = 1
DECLARE @DynamicSQL varchar(MAX)
DECLARE @reseedIndex AS CURSOR
SET @reseedIndex = CURSOR FOR
    SELECT * from #ReseedCommands;
OPEN @reseedIndex;
FETCH NEXT FROM @reseedIndex INTO @DynamicSQL
WHILE @@FETCH_STATUS = 0
BEGIN
    EXECUTE (@DynamicSQL)
    FETCH NEXT FROM @reseedIndex INTO @DynamicSQL
END
CLOSE @reseedIndex
DEALLOCATE @reseedIndex
DROP TABLE #ReseedCommands

END

DECLARE
@DatabaseName varChar (50) = NULL,
@SchemaName varchar(50) = NULL,
@TableName varchar(50) = NULL
/*
--------------------------------------------------------------------------------
Print the README
--------------------------------------------------------------------------------
*/
	PRINT 
	'-----------README----------: 
Purpose: 
When you need to track the Primary and Foreign Key path of tables, this query will
help by showing all of the Primary Keys and Foreign Keys, and which tables use the
Primary Key of the specified table, as well as which tables the Foreign Keys 
belong to.
Additionally, this query is meant to help you find Database Names, like @DatabaseName
and Table Names that belong to @SchemaName, like @TableName. 
To Use: 
-@DatabaseName
Start by entering the database name that you would like to find. If you 
include % in the name you will find all Databases "like @DatabaseName"
If you enter the empty string (''''), this query will use the active database.
-@SchemaName
Next, type in the schema you would like to search. For example, if you want to see
the Keys that connect to "dbo.Example", you would type ''dbo''. If you include %
in the SchemaName you will find all Schema "like @SchemaName"
If you don''t know the schema, you can leave this blank, but be aware that some 
table names are repeated on multiple schema. You will see this reflected in your 
results.
-@TableName
Finally, type in the table that you would like to search. If you were looking for 
"dbo.Example", you would type ''Example''. If you want to search through all tables
in the schema requested prior to this, leave this blank or type in an empty string.
If you include % in the TableName you will find all tables "like @TableName"
-Final Result:
Once you have included all 3 parameters without % you will see all of the 
Primary-Foreign Key relationships.

----------END README----------
';
DECLARE @DynamicSQL varchar(max),
		@DynamicWhere0 varchar(max) = '1 = 1 ',
		@DynamicWhere1 varchar(max) = '1 = 1 '
IF @DatabaseName IS NULL
BEGIN
	SELECT name FROM sys.Databases
END
ELSE IF @DatabaseName like '%!%%' Escape '!'
BEGIN
	SELECT name FROM sys.Databases WHERE name like @DatabaseName
END
ELSE IF @DatabaseName != ''
		AND NOT EXISTS(SELECT * FROM sys.Databases WHERE name = @DatabaseName)
BEGIN
	PRINT @DatabaseName + ' {Database} does not exist. Please try surrounding your search term with % to find existing databases'
END
ELSE 
BEGIN
	IF @DatabaseName = ''
	BEGIN
		SELECT @DatabaseName = DB_NAME()
	END
--Set the Dynamic SQL to start chain reaction from Information_schema
	SET @DynamicSQL = 'SELECT TABLE_SCHEMA + ''.'' + TABLE_NAME FROM ' + @DatabaseName + '.INFORMATION_SCHEMA.TABLES '
	IF @SchemaName like '%!%%' Escape '!'
	BEGIN
		SET @DynamicWhere0 = 'TABLE_SCHEMA LIKE ' + @SchemaName + ' '
	END
	IF @TableName like '%!%%' Escape '!'
	BEGIN
		SET @DynamicWhere1 = 'TABLE_NAME LIKE ' + @TableName + ' '
	END
	SET @DynamicSQL = @DynamicSQL + 'WHERE ' + @DynamicWhere0 + 'AND ' + @DynamicWhere1
END
IF @SchemaName IS NOT NULL AND @TableName IS NOT NULL
BEGIN
SET @DynamicSQL = 
'SELECT CO1.COLUMN_NAME AS [ColumnName],
	   ISNULL(TC1.CONSTRAINT_TYPE, '''') AS [KeyType],
	   ISNULL(CU2.COLUMN_NAME, '''') AS [PrimaryKeyColumn],
	   ISNULL(CU2.TABLE_SCHEMA + ''.'' + CU2.TABLE_NAME, '''') AS [PrimaryKeySchema&Table],
	   ISNULL(TC1.CONSTRAINT_NAME, '''') AS [TableConstraintName],
	   ISNULL(CU3.TABLE_SCHEMA + ''.'' + CU3.TABLE_NAME, '''') AS [ForeignKeySchema&Table]
	   
FROM '+ @DatabaseName + '.INFORMATION_SCHEMA.COLUMNS CO1
LEFT OUTER JOIN '+ @DatabaseName + '.INFORMATION_SCHEMA.KEY_COLUMN_USAGE CU1 (NOLOCK)
ON CO1.TABLE_NAME = CU1.TABLE_NAME 
AND CO1.COLUMN_NAME = CU1.COLUMN_NAME
LEFT OUTER JOIN '+ @DatabaseName + '.INFORMATION_SCHEMA.TABLE_CONSTRAINTS TC1 (NOLOCK)
ON CU1.CONSTRAINT_NAME = TC1.CONSTRAINT_NAME
LEFT OUTER JOIN '+ @DatabaseName + '.INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS RC1 (NOLOCK)
ON TC1.CONSTRAINT_NAME = RC1.CONSTRAINT_NAME
LEFT OUTER JOIN '+ @DatabaseName + '.INFORMATION_SCHEMA.KEY_COLUMN_USAGE CU2 (NOLOCK)
ON RC1.UNIQUE_CONSTRAINT_NAME = CU2.CONSTRAINT_NAME
LEFT OUTER JOIN '+ @DatabaseName + '.INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS RC3 (NOLOCK)
ON TC1.CONSTRAINT_NAME = RC3.UNIQUE_CONSTRAINT_NAME
LEFT OUTER JOIN '+ @DatabaseName + '.INFORMATION_SCHEMA.KEY_COLUMN_USAGE CU3 (NOLOCK)
ON RC3.CONSTRAINT_NAME = CU3.CONSTRAINT_NAME
WHERE CO1.TABLE_SCHEMA + ''.'' + CO1.TABLE_NAME = ''' + @SchemaName + '.' + @TableName + '''
AND TC1.CONSTRAINT_TYPE IS NOT NULL
ORDER BY KeyType DESC, [PrimaryKeySchema&Table], [ForeignKeySchema&Table]'
END
EXEC(@DynamicSQL)
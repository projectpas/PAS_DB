--select * from dbo.Employee      
--EXEC AutoCompleteDropdowns 'Employee','EmployeeId','FirstName','sur',1,20,'108,109,11',1      
--select * from dbo.Customer      
--EXEC AutoCompleteDropdowns 'ItemMaster','ItemMasterId','PartNumber','',1,'50','',1      
--EXEC AutoCompleteDropdowns 'Employee','EmployeeId','FirstName','',1,10      
--EXEC AutoCompleteDropdowns 'AssetStatus','AssetStatusId','Name','',0,200,'12'      
--EXEC AutoCompleteDropdowns 'Customer','CustomerId','Name','',1,'0','0',1      
--EXEC AutoCompleteDropdowns 'MasterParts','MasterPartId','PartNumber','',1,'20','0',1  
--EXEC AutoCompleteDropdowns 'Vendor','VendorId','VendorName','fa',0,0,'0',5  
CREATE   PROCEDURE [dbo].[AutoCompleteDropdowns]      
@TableName VARCHAR(50) = null,      
@Parameter1 VARCHAR(50)= null,      
@Parameter2 VARCHAR(100)= null,      
@Parameter3 VARCHAR(50)= null,      
@Parameter4 bit = true,      
@Count VARCHAR(10)=0,      
@Idlist VARCHAR(max)='0',    
@MasterCompanyId int      
AS      
BEGIN  
   
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
  SET NOCOUNT ON    
  BEGIN TRY    
  
  DECLARE @Sql NVARCHAR(MAX);    
      
  CREATE TABLE #TempTable(      
   Value BIGINT,      
   Label VARCHAR(MAX),  
   MasterCompanyId int)        
    
  IF(@Count = '0')       
  BEGIN    
  print '00'  
  IF(@TableName='Employee')      
  BEGIN      
         IF(@Parameter4=1)      
         BEGIN        
               SELECT DISTINCT  EmployeeId AS Value,FirstName+' '+LastName AS Label      
               FROM dbo.Employee WITH(NOLOCK) WHERE MasterCompanyId = @MasterCompanyId AND (IsActive=1 AND ISNULL(IsDeleted,0)=0 AND (FirstName LIKE '%' + @Parameter3 + '%' OR LastName  LIKE '%' + @Parameter3 + '%'))      
               UNION       
               SELECT DISTINCT  EmployeeId AS Value,FirstName+' '+LastName AS Label FROM dbo.Employee  WITH(NOLOCK)  
               WHERE MasterCompanyId = @MasterCompanyId AND EmployeeId IN (SELECT Item FROM DBO.SPLITSTRING(@Idlist,',')) ORDER BY FirstName+' '+LastName          
         END      
   ELSE      
         BEGIN      
               SELECT DISTINCT  EmployeeId AS Value,FirstName+' '+LastName AS Label      
               FROM dbo.Employee WITH(NOLOCK) WHERE  MasterCompanyId = @MasterCompanyId AND IsActive=1 AND ISNULL(IsDeleted,0)=0  AND FirstName LIKE '%' + @Parameter3 + '%' OR LastName  LIKE '%' + @Parameter3 + '%'      
               UNION       
               SELECT DISTINCT  EmployeeId AS Value,FirstName+' '+LastName AS Label  FROM dbo.Employee WITH(NOLOCK)  
               WHERE MasterCompanyId = @MasterCompanyId AND EmployeeId IN (SELECT Item FROM DBO.SPLITSTRING(@Idlist,','))   
         END          
     END  
  ELSE IF(@TableName='Task')   
  BEGIN  
   IF(@Parameter4=1)      
         BEGIN        
               SELECT DISTINCT  TaskId AS Value,Description AS Label,Sequence      
               FROM dbo.Task WITH(NOLOCK) WHERE MasterCompanyId = @MasterCompanyId AND (IsActive=1 AND ISNULL(IsDeleted,0)=0 AND (Description LIKE '%' + @Parameter3 + '%'))      
               UNION       
               SELECT DISTINCT  TaskId AS Value,Description AS Label,Sequence FROM dbo.Task  WITH(NOLOCK)  
               WHERE MasterCompanyId = @MasterCompanyId AND TaskId IN (SELECT Item FROM DBO.SPLITSTRING(@Idlist,',')) ORDER BY Sequence asc          
         END      
   ELSE      
         BEGIN      
               SELECT DISTINCT   TaskId AS Value,Description AS Label,Sequence       
               FROM dbo.Task WITH(NOLOCK) WHERE  MasterCompanyId = @MasterCompanyId AND IsActive=1 AND ISNULL(IsDeleted,0)=0  AND Description LIKE '%' + @Parameter3 + '%'      
               UNION       
               SELECT DISTINCT   TaskId AS Value,Description AS Label,Sequence      FROM dbo.Task WITH(NOLOCK)  
               WHERE MasterCompanyId = @MasterCompanyId AND TaskId IN (SELECT Item FROM DBO.SPLITSTRING(@Idlist,','))  ORDER BY Sequence asc   
         END      
  END  
  ELSE IF(@TableName='ConsigneeLot')   
  BEGIN  
   IF(@Parameter4=1)      
         BEGIN   
               SELECT DISTINCT LotId AS Value,LotNumber AS Label      
               FROM dbo.LOT WITH(NOLOCK) WHERE MasterCompanyId = @MasterCompanyId AND (IsActive=1 AND ISNULL(IsDeleted,0)=0 AND (LotNumber LIKE '%' + @Parameter3 + '%'))  AND LotId NOT IN (SELECT ISNULL(LotId,0)  FROM LotConsignment)   
               UNION       
               SELECT DISTINCT  LotId AS Value,LotNumber AS Label FROM dbo.Lot  WITH(NOLOCK)  
               WHERE MasterCompanyId = @MasterCompanyId AND LotId IN (SELECT Item FROM DBO.SPLITSTRING(@Idlist,','))  AND LotId NOT IN (SELECT ISNULL(LotId,0)  FROM LotConsignment) ORDER BY LotId DESC          
         END      
   ELSE      
         BEGIN      
               SELECT DISTINCT LotId AS Value,LotNumber AS Label      
               FROM dbo.LOT WITH(NOLOCK) WHERE MasterCompanyId = @MasterCompanyId AND (IsActive=1 AND ISNULL(IsDeleted,0)=0 AND (LotNumber LIKE '%' + @Parameter3 + '%')) AND LotId NOT IN (SELECT ISNULL(LotId,0)  FROM LotConsignment)      
               UNION       
               SELECT DISTINCT  LotId AS Value,LotNumber AS Label FROM dbo.Lot  WITH(NOLOCK)  
               WHERE MasterCompanyId = @MasterCompanyId AND LotId IN (SELECT Item FROM DBO.SPLITSTRING(@Idlist,',')) AND LotId NOT IN (SELECT ISNULL(LotId,0)  FROM LotConsignment) ORDER BY LotId DESC      
         END      
  END  

  ELSE IF(@TableName='LotLatest')   
  BEGIN  
   IF(@Parameter4=1)      
         BEGIN   
               SELECT DISTINCT LotId AS Value,LotNumber AS Label      
               FROM dbo.LOT WITH(NOLOCK) WHERE MasterCompanyId = @MasterCompanyId AND (IsActive=1 AND ISNULL(IsDeleted,0)=0 AND (LotNumber LIKE '%' + @Parameter3 + '%'))   
               UNION       
               SELECT DISTINCT  LotId AS Value,LotNumber AS Label FROM dbo.Lot  WITH(NOLOCK)  
               WHERE MasterCompanyId = @MasterCompanyId AND LotId IN (SELECT Item FROM DBO.SPLITSTRING(@Idlist,','))  ORDER BY LotId DESC          
         END      
   ELSE      
         BEGIN      
               SELECT DISTINCT LotId AS Value,LotNumber AS Label      
               FROM dbo.LOT WITH(NOLOCK) WHERE MasterCompanyId = @MasterCompanyId AND (IsActive=1 AND ISNULL(IsDeleted,0)=0 AND (LotNumber LIKE '%' + @Parameter3 + '%'))      
               UNION       
               SELECT DISTINCT  LotId AS Value,LotNumber AS Label FROM dbo.Lot  WITH(NOLOCK)  
               WHERE MasterCompanyId = @MasterCompanyId AND LotId IN (SELECT Item FROM DBO.SPLITSTRING(@Idlist,',')) ORDER BY LotId DESC      
         END      

  END 
     ELSE      
     BEGIN      
     IF(@Parameter4=1)      
     BEGIN   
    IF(@TableName='ItemMaster')  
    BEGIN  
   SELECT TOP 20 IM.ItemMasterId as Value, Im.partnumber as PartNumber,   
   im.partnumber + (CASE WHEN (SELECT COUNT(ISNULL(SD.[ManufacturerId], 0)) FROM [dbo].[ItemMaster]  SD WITH(NOLOCK)  WHERE im.partnumber = SD.partnumber AND SD.MasterCompanyId = @MasterCompanyId) > 1 then ' - '+ IM.ManufacturerName ELSE '' END) AS Label
,  
   IM.MasterCompanyId,im.ManufacturerName As ManufacturerName   
   FROM dbo.ItemMaster IM WHERE Im.MasterCompanyId = @MasterCompanyId AND ISNULL(IsActive,1) = 1 AND ISNULL(IsDeleted,0) = 0 AND Im.PartNumber like '%'+ @Parameter3+'%'  
  
   UNION  
  
   SELECT IM.ItemMasterId as Value, Im.partnumber as PartNumber,     
       im.partnumber + (CASE WHEN (SELECT COUNT(ISNULL(SD.[ManufacturerId], 0))   
       FROM [dbo].[ItemMaster]  SD WITH(NOLOCK)    
       WHERE im.partnumber = SD.partnumber AND SD.MasterCompanyId = @MasterCompanyId) > 1 then ' - '+ IM.ManufacturerName ELSE '' END) AS Label,  
      IM.MasterCompanyId,im.ManufacturerName As ManufacturerName     
   FROM dbo.ItemMaster IM WHERE Im.MasterCompanyId = @MasterCompanyId AND IM.ItemMasterId in (SELECT Item FROM DBO.SPLITSTRING(@Idlist,','))    
  
    END  
	ELSE IF(@TableName='ItemMasterALL')  
    BEGIN  
   SELECT  IM.ItemMasterId as Value, Im.partnumber as PartNumber,   
   im.partnumber + (CASE WHEN (SELECT COUNT(ISNULL(SD.[ManufacturerId], 0)) FROM [dbo].[ItemMaster]  SD WITH(NOLOCK)  WHERE im.partnumber = SD.partnumber AND SD.MasterCompanyId = @MasterCompanyId) > 1 then ' - '+ IM.ManufacturerName ELSE '' END) AS Label
,  
   IM.MasterCompanyId,im.ManufacturerName As ManufacturerName   
   FROM dbo.ItemMaster IM WHERE Im.MasterCompanyId = @MasterCompanyId AND ISNULL(IsActive,1) = 1 AND ISNULL(IsDeleted,0) = 0 AND Im.PartNumber like '%'+ @Parameter3+'%'  
  
   UNION  
  
   SELECT IM.ItemMasterId as Value, Im.partnumber as PartNumber,     
       im.partnumber + (CASE WHEN (SELECT COUNT(ISNULL(SD.[ManufacturerId], 0))   
       FROM [dbo].[ItemMaster]  SD WITH(NOLOCK)    
       WHERE im.partnumber = SD.partnumber AND SD.MasterCompanyId = @MasterCompanyId) > 1 then ' - '+ IM.ManufacturerName ELSE '' END) AS Label,  
      IM.MasterCompanyId,im.ManufacturerName As ManufacturerName     
   FROM dbo.ItemMaster IM WHERE Im.MasterCompanyId = @MasterCompanyId AND IM.ItemMasterId in (SELECT Item FROM DBO.SPLITSTRING(@Idlist,','))    
  
    END
     ELSE IF(@TableName='ConsigneeLot')   
     BEGIN  
		SELECT DISTINCT LotId AS Value,LotNumber AS Label      
				   FROM dbo.LOT WITH(NOLOCK) WHERE MasterCompanyId = @MasterCompanyId AND (IsActive=1 AND ISNULL(IsDeleted,0)=0 AND (LotNumber LIKE '%' + @Parameter3 + '%'))   
		  AND LotId NOT IN (SELECT ISNULL(LotId,0)  FROM LotConsignment)  
				   UNION       
				   SELECT DISTINCT  LotId AS Value,LotNumber AS Label FROM dbo.Lot  WITH(NOLOCK)  
				   WHERE MasterCompanyId = @MasterCompanyId AND LotId IN (SELECT Item FROM DBO.SPLITSTRING(@Idlist,',')) AND LotId NOT IN (SELECT ISNULL(LotId,0)  FROM LotConsignment) ORDER BY LotId DESC       
     END  
	 ELSE IF(@TableName='LotLatest')   
     BEGIN  
		SELECT DISTINCT LotId AS Value,LotNumber AS Label      
				   FROM dbo.LOT WITH(NOLOCK) WHERE MasterCompanyId = @MasterCompanyId AND (IsActive=1 AND ISNULL(IsDeleted,0)=0 AND (LotNumber LIKE '%' + @Parameter3 + '%')) 
				   UNION       
				   SELECT DISTINCT  LotId AS Value,LotNumber AS Label FROM dbo.Lot  WITH(NOLOCK)  
				   WHERE MasterCompanyId = @MasterCompanyId AND LotId IN (SELECT Item FROM DBO.SPLITSTRING(@Idlist,',')) ORDER BY LotId DESC       
     END 
    ELSE IF(@TableName='ItemMasterNonStock')  
    BEGIN  
   SELECT IMN.MasterPartId as Value, IMN.partnumber as PartNumber,   
   IMN.partnumber + (CASE WHEN (SELECT COUNT(ISNULL(SD.[ManufacturerId], 0)) FROM [dbo].[ItemMasterNonStock]  SD WITH(NOLOCK)  WHERE IMN.partnumber = SD.partnumber AND SD.MasterCompanyId = @MasterCompanyId) > 1 then ' - '+ IMN.Manufacturer ELSE '' END) AS
 Label,  
   IMN.MasterCompanyId,IMN.Manufacturer As ManufacturerName   
   FROM dbo.ItemMasterNonStock IMN WHERE IMN.MasterCompanyId = @MasterCompanyId AND ISNULL(IsActive,1) = 1 AND ISNULL(IsDeleted,0) = 0 AND IMN.PartNumber like '%'+ @Parameter3+'%'  
    END  
    ELSE IF(@TableName='LotConsignment')  
    BEGIN  
   SELECT LC.ConsignmentId AS Value,   
       LC.ConsignmentNumber AS Label,   
       LC.MasterCompanyId AS MasterCompanyId,  
       LC.ConsigneeName AS ConsigneeName  
       FROM dbo.LotConsignment LC WHERE LC.MasterCompanyId = @MasterCompanyId AND ISNULL(IsActive,1) = 1 AND ISNULL(IsDeleted,0) = 0 AND LC.ConsignmentNumber like '%'+ @Parameter3+'%'  
    END  
    ELSE  
    BEGIN  
   SET @Sql = N'INSERT INTO #TempTable (Value, Label, MasterCompanyId)   
           SELECT DISTINCT  CAST ( '+@Parameter1+' AS BIGINT) As Value,  
                   CAST ( '+ @Parameter2+  ' AS VARCHAR(MAX)) AS Label,   
             MasterCompanyId FROM dbo.'+@TableName+       
           ' WITH(NOLOCK) WHERE MasterCompanyId = ' + CAST ( @MasterCompanyId AS nvarchar(50) ) + ' AND CAST ( '+@Parameter1+' AS VARCHAR(MAX) ) IN (SELECT Item FROM DBO.SPLITSTRING('''+ @Idlist +''','',''))      
              
            INSERT INTO #TempTable (Value, Label, MasterCompanyId)   
            SELECT DISTINCT  CAST ( '+@Parameter1+' AS BIGINT) As Value,  
                CAST(' + @Parameter2 + ' AS VARCHAR(MAX)) AS Label,  
       MasterCompanyId FROM dbo.' + @TableName+       
           ' WITH(NOLOCK) WHERE MasterCompanyId = ' + CAST ( @MasterCompanyId AS nvarchar(50) ) + ' AND IsActive=1 AND ISNULL(IsDeleted,0)=0 AND CAST ( '+@Parameter2+' AS VARCHAR(MAX)) !='''' AND '+@Parameter2+'  LIKE ''%'+ @Parameter3 +'%'''     
    END  
      
     END      
     ELSE      
     BEGIN    
   SET @Sql = N'INSERT INTO #TempTable (Value, Label, MasterCompanyId)   
                          SELECT DISTINCT  CAST ( '+@Parameter1+' AS BIGINT) As Value,  
        CAST(' + @Parameter2 + ' AS VARCHAR(MAX)) AS Label,  
        MasterCompanyId FROM  dbo.'+@TableName+       
   ' WITH(NOLOCK) WHERE MasterCompanyId = ' + CAST ( @MasterCompanyId AS nvarchar(50) ) + ' AND CAST ( '+@Parameter1+' AS VARCHAR(MAX) ) IN (SELECT Item FROM DBO.SPLITSTRING('''+ @Idlist +''','',''))      
               
   INSERT INTO #TempTable (Value, Label, MasterCompanyId)   
            SELECT DISTINCT  CAST ( '+@Parameter1+' AS BIGINT) As Value,  
      CAST(' + @Parameter2 + ' AS VARCHAR(MAX)) AS Label,  
      MasterCompanyId FROM dbo.'+@TableName+       
   ' WITH(NOLOCK) WHERE MasterCompanyId = ' + CAST ( @MasterCompanyId AS nvarchar(50) ) + ' AND IsActive=1 AND ISNULL(IsDeleted,0)=0 AND CAST ( '+@Parameter2+' AS VARCHAR(MAX)) !='''' AND '+@Parameter2+'  LIKE ''%'+ @Parameter3 +'%''';      
     END      
     END   
  END  
  ELSE  
  BEGIN  
  IF(@TableName='Employee')      
  BEGIN      
  IF(@Parameter4=1)      
  BEGIN        
  SELECT DISTINCT top 20 EmployeeId AS Value,FirstName+' '+LastName AS Label      
            FROM dbo.Employee WITH(NOLOCK) WHERE MasterCompanyId = @MasterCompanyId AND (IsActive=1 AND ISNULL(IsDeleted,0)=0 AND (FirstName LIKE '%' + @Parameter3 + '%' OR LastName  LIKE '%' + @Parameter3 + '%'))      
   UNION       
  SELECT DISTINCT  EmployeeId AS Value,FirstName+' '+LastName AS Label      
            FROM dbo.Employee  WITH(NOLOCK)      
  WHERE MasterCompanyId = @MasterCompanyId AND EmployeeId in (SELECT Item FROM DBO.SPLITSTRING(@Idlist,','))  
  END      
  ELSE      
  BEGIN      
  SELECT DISTINCT top 20 EmployeeId AS Value,FirstName+' '+LastName AS Label      
            FROM dbo.Employee WITH(NOLOCK)  WHERE  MasterCompanyId = @MasterCompanyId AND IsActive=1 AND ISNULL(IsDeleted,0)=0  AND (FirstName LIKE '%' + @Parameter3 + '%' OR LastName  LIKE '%' + @Parameter3 + '%')      
   UNION       
  SELECT DISTINCT  EmployeeId AS Value,FirstName+' '+LastName AS Label      
            FROM dbo.Employee WITH(NOLOCK)       
   WHERE MasterCompanyId = @MasterCompanyId AND EmployeeId in (SELECT Item FROM DBO.SPLITSTRING(@Idlist,','))  
  END  
  END  
  ELSE IF(@TableName='Task')   
  BEGIN  
   IF(@Parameter4=1)      
         BEGIN        
               SELECT DISTINCT  TaskId AS Value,Description AS Label,Sequence      
               FROM dbo.Task WITH(NOLOCK) WHERE MasterCompanyId = @MasterCompanyId AND (IsActive=1 AND ISNULL(IsDeleted,0)=0 AND (Description LIKE '%' + @Parameter3 + '%'))      
               UNION       
               SELECT DISTINCT  TaskId AS Value,Description AS Label,Sequence FROM dbo.Task  WITH(NOLOCK)  
               WHERE MasterCompanyId = @MasterCompanyId AND TaskId IN (SELECT Item FROM DBO.SPLITSTRING(@Idlist,',')) ORDER BY Sequence asc          
         END      
   ELSE      
         BEGIN      
               SELECT DISTINCT   TaskId AS Value,Description AS Label,Sequence       
               FROM dbo.Task WITH(NOLOCK) WHERE  MasterCompanyId = @MasterCompanyId AND IsActive=1 AND ISNULL(IsDeleted,0)=0  AND Description LIKE '%' + @Parameter3 + '%'      
               UNION       
               SELECT DISTINCT   TaskId AS Value,Description AS Label,Sequence  FROM dbo.Task WITH(NOLOCK)  
               WHERE MasterCompanyId = @MasterCompanyId AND TaskId IN (SELECT Item FROM DBO.SPLITSTRING(@Idlist,','))  ORDER BY Sequence asc     
         END      
  END  
   ELSE IF(@TableName='ConsigneeLot')   
   BEGIN  
    SELECT DISTINCT TOP 20 LotId AS Value,LotNumber AS Label      
               FROM dbo.LOT WITH(NOLOCK) WHERE MasterCompanyId = @MasterCompanyId AND (IsActive=1 AND ISNULL(IsDeleted,0)=0 AND (LotNumber LIKE '%' + @Parameter3 + '%'))    
      AND LotId NOT IN (SELECT ISNULL(LotId,0)  FROM LotConsignment)  
               UNION       
               SELECT DISTINCT  LotId AS Value,LotNumber AS Label FROM dbo.Lot  WITH(NOLOCK)  
               WHERE MasterCompanyId = @MasterCompanyId AND LotId IN (SELECT Item FROM DBO.SPLITSTRING(@Idlist,','))  
      AND LotId NOT IN (SELECT ISNULL(LotId,0)  FROM LotConsignment) ORDER BY LotId DESC       
   END  
   ELSE IF(@TableName='LotLatest')   
   BEGIN  
    SELECT DISTINCT TOP 20 LotId AS Value,LotNumber AS Label      
               FROM dbo.LOT WITH(NOLOCK) WHERE MasterCompanyId = @MasterCompanyId AND (IsActive=1 AND ISNULL(IsDeleted,0)=0 AND (LotNumber LIKE '%' + @Parameter3 + '%'))    
     
               UNION       
               SELECT DISTINCT  LotId AS Value,LotNumber AS Label FROM dbo.Lot  WITH(NOLOCK)  
               WHERE MasterCompanyId = @MasterCompanyId AND LotId IN (SELECT Item FROM DBO.SPLITSTRING(@Idlist,','))  
       ORDER BY LotId DESC       
   END  
    ELSE IF(@TableName='ItemMasterNonStock')  
    BEGIN  
   SELECT IMN.MasterPartId as Value, IMN.partnumber as PartNumber,   
   IMN.partnumber + (CASE WHEN (SELECT COUNT(ISNULL(SD.[ManufacturerId], 0)) FROM [dbo].[ItemMasterNonStock]  SD WITH(NOLOCK)  WHERE IMN.partnumber = SD.partnumber AND SD.MasterCompanyId = @MasterCompanyId) > 1 then ' - '+ IMN.Manufacturer ELSE '' END) AS
 Label,  
   IMN.MasterCompanyId,IMN.Manufacturer As ManufacturerName   
   FROM dbo.ItemMasterNonStock IMN WHERE IMN.MasterCompanyId = @MasterCompanyId AND ISNULL(IsActive,1) = 1 AND ISNULL(IsDeleted,0) = 0 AND IMN.PartNumber like '%'+ @Parameter3+'%'  
    END  
  ELSE      
  BEGIN      
  IF(@Parameter4=1)      
  BEGIN   
    IF(@TableName='ItemMaster')  
    BEGIN  
   SELECT TOP 20 IM.ItemMasterId as Value, Im.partnumber as PartNumber,   
   im.partnumber + (CASE WHEN (SELECT COUNT(ISNULL(SD.[ManufacturerId], 0)) FROM [dbo].[ItemMaster]  SD WITH(NOLOCK)  WHERE im.partnumber = SD.partnumber AND SD.MasterCompanyId = @MasterCompanyId) > 1 then ' - '+ IM.ManufacturerName ELSE '' END) AS Label,
  
   IM.MasterCompanyId, im.ManufacturerName AS ManufacturerName  
   FROM dbo.ItemMaster IM WHERE Im.MasterCompanyId = @MasterCompanyId AND ISNULL(IsActive,1) = 1 AND ISNULL(IsDeleted,0) = 0 AND Im.PartNumber like '%'+ @Parameter3+'%'  
  
   UNION   
     SELECT IM.ItemMasterId as Value, Im.partnumber as PartNumber,     
     im.partnumber + (CASE WHEN (SELECT COUNT(ISNULL(SD.[ManufacturerId], 0)) FROM [dbo].[ItemMaster]  SD WITH(NOLOCK)    
     WHERE im.partnumber = SD.partnumber AND SD.MasterCompanyId = @MasterCompanyId) > 1 then ' - '+ IM.ManufacturerName ELSE '' END) AS Label,  
     IM.MasterCompanyId, im.ManufacturerName AS ManufacturerName    
     FROM dbo.ItemMaster IM WHERE Im.MasterCompanyId = @MasterCompanyId AND IM.ItemMasterId in (SELECT Item FROM DBO.SPLITSTRING(@Idlist,','))   
      
    END  
	ELSE IF(@TableName='ItemMasterALL')  
    BEGIN  
   SELECT  IM.ItemMasterId as Value, Im.partnumber as PartNumber,   
   im.partnumber + (CASE WHEN (SELECT COUNT(ISNULL(SD.[ManufacturerId], 0)) FROM [dbo].[ItemMaster]  SD WITH(NOLOCK)  WHERE im.partnumber = SD.partnumber AND SD.MasterCompanyId = @MasterCompanyId) > 1 then ' - '+ IM.ManufacturerName ELSE '' END) AS Label
,  
   IM.MasterCompanyId,im.ManufacturerName As ManufacturerName   
   FROM dbo.ItemMaster IM WHERE Im.MasterCompanyId = @MasterCompanyId AND ISNULL(IsActive,1) = 1 AND ISNULL(IsDeleted,0) = 0 AND Im.PartNumber like '%'+ @Parameter3+'%'  
  
   UNION  
  
   SELECT IM.ItemMasterId as Value, Im.partnumber as PartNumber,     
       im.partnumber + (CASE WHEN (SELECT COUNT(ISNULL(SD.[ManufacturerId], 0))   
       FROM [dbo].[ItemMaster]  SD WITH(NOLOCK)    
       WHERE im.partnumber = SD.partnumber AND SD.MasterCompanyId = @MasterCompanyId) > 1 then ' - '+ IM.ManufacturerName ELSE '' END) AS Label,  
      IM.MasterCompanyId,im.ManufacturerName As ManufacturerName     
   FROM dbo.ItemMaster IM WHERE Im.MasterCompanyId = @MasterCompanyId AND IM.ItemMasterId in (SELECT Item FROM DBO.SPLITSTRING(@Idlist,','))    
  
    END
    ELSE IF(@TableName='ItemMasterNonStock')  
    BEGIN  
   SELECT TOP 20 IMN.MasterPartId as Value, IMN.partnumber as PartNumber,   
   IMN.partnumber + (CASE WHEN (SELECT COUNT(ISNULL(SD.[ManufacturerId], 0)) FROM [dbo].[ItemMasterNonStock]  SD WITH(NOLOCK)  WHERE IMN.partnumber = SD.partnumber AND SD.MasterCompanyId = @MasterCompanyId) > 1 then ' - '+ IMN.Manufacturer ELSE '' END) AS
 Label,  
   IMN.MasterCompanyId,IMN.Manufacturer As ManufacturerName   
   FROM dbo.ItemMasterNonStock IMN WHERE IMN.MasterCompanyId = @MasterCompanyId AND ISNULL(IsActive,1) = 1 AND ISNULL(IsDeleted,0) = 0 AND IMN.PartNumber like '%'+ @Parameter3+'%'  
    END  
     ELSE IF(@TableName='ConsigneeLot')   
      BEGIN  
      SELECT TOP 20 LotId AS Value,LotNumber AS Label      
        FROM dbo.LOT WITH(NOLOCK) WHERE MasterCompanyId = @MasterCompanyId AND (IsActive=1 AND ISNULL(IsDeleted,0)=0 AND (LotNumber LIKE '%' + @Parameter3 + '%'))  AND LotId NOT IN (SELECT ISNULL(LotId,0)  FROM LotConsignment)      
         UNION       
         SELECT DISTINCT  LotId AS Value,LotNumber AS Label FROM dbo.Lot  WITH(NOLOCK)  
         WHERE MasterCompanyId = @MasterCompanyId AND LotId IN (SELECT Item FROM DBO.SPLITSTRING(@Idlist,',')) AND LotId NOT IN (SELECT ISNULL(LotId,0)  FROM LotConsignment) ORDER BY LotId DESC       
      END  
	  ELSE IF(@TableName='LotLatest')   
      BEGIN  
      SELECT TOP 20 LotId AS Value,LotNumber AS Label      
        FROM dbo.LOT WITH(NOLOCK) WHERE MasterCompanyId = @MasterCompanyId AND (IsActive=1 AND ISNULL(IsDeleted,0)=0 AND (LotNumber LIKE '%' + @Parameter3 + '%'))    
         UNION       
         SELECT DISTINCT  LotId AS Value,LotNumber AS Label FROM dbo.Lot  WITH(NOLOCK)  
         WHERE MasterCompanyId = @MasterCompanyId AND LotId IN (SELECT Item FROM DBO.SPLITSTRING(@Idlist,','))  ORDER BY LotId DESC       
      END
    ELSE  
    BEGIN  
    SET @Sql = N'INSERT INTO #TempTable (Value, Label, MasterCompanyId)   
             SELECT DISTINCT TOP ' +@Count+ ' CAST ( '+@Parameter1+' AS BIGINT) As Value,  
               CAST ( '+ @Parameter2+  ' AS VARCHAR(MAX)) AS Label,   
               MasterCompanyId FROM  dbo.'+@TableName+       
      ' WHERE MasterCompanyId =  '  + CAST (@MasterCompanyId AS nvarchar(50)) + '  AND CAST ( '+@Parameter1+' AS VARCHAR(MAX) ) IN (SELECT Item FROM DBO.SPLITSTRING('''+ @Idlist +''','',''))      
              
    INSERT INTO #TempTable (Value, Label, MasterCompanyId)   
        SELECT DISTINCT TOP ' +@Count+ ' CAST ( '+@Parameter1+' AS BIGINT) As Value,  
         CAST('+ @Parameter2 + ' AS VARCHAR(MAX)) AS Label,  
         MasterCompanyId FROM  dbo.'+@TableName+       
      ' WHERE MasterCompanyId =  '  + CAST (@MasterCompanyId AS nvarchar(50)) + '  AND IsActive=1 AND ISNULL(IsDeleted,0)=0 AND CAST ( '+@Parameter2+' AS VARCHAR(MAX)) !='''' AND '+@Parameter2+'  LIKE ''%'+ @Parameter3 +'%'''      
    END  
   END      
   ELSE      
   BEGIN  
     SET @Sql = N'INSERT INTO #TempTable (Value, Label, MasterCompanyId)   
                          SELECT DISTINCT TOP ' +@Count+ ' CAST ( '+@Parameter1+' AS BIGINT) As Value,  
        CAST ( '+ @Parameter2+  ' AS VARCHAR(MAX)) AS Label,  
        MasterCompanyId FROM  dbo.'+@TableName+       
          ' WHERE MasterCompanyId =  '  + CAST (@MasterCompanyId AS nvarchar(50)) + '  AND CAST ( '+@Parameter1+' AS VARCHAR(MAX) ) IN (SELECT Item FROM DBO.SPLITSTRING('''+ @Idlist +''','',''))      
               
          INSERT INTO #TempTable (Value, Label, MasterCompanyId)   
            SELECT DISTINCT TOP ' +@Count+ ' CAST ( '+@Parameter1+' AS BIGINT) As Value,  
      CAST('+ @Parameter2 + ' AS VARCHAR(MAX)) AS Label,  
      MasterCompanyId FROM  dbo.'+@TableName+       
          ' WHERE MasterCompanyId =  '  + CAST (@MasterCompanyId AS nvarchar(50)) + '  AND IsActive=1 AND ISNULL(IsDeleted,0)=0 AND CAST ( '+@Parameter2+' AS VARCHAR(MAX)) !='''' AND '+@Parameter2+'  LIKE ''%'+ @Parameter3 +'%''';      
    END      
   END      
  END  
  PRINT @Sql      
  EXEC sp_executesql @Sql;      
  SELECT DISTINCT * FROM #TempTable  WHERE MasterCompanyId = @MasterCompanyId ORDER BY Label       
  DROP Table #TempTable    
  
END TRY  
BEGIN CATCH    
 DECLARE @ErrorLogID INT  
   ,@DatabaseName VARCHAR(100) = db_name()  
   -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
   ,@AdhocComments VARCHAR(150) = 'AutoCompleteDropdowns'  
   ,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@TableName, '') as varchar(100))  
      + '@Parameter2 = ''' + CAST(ISNULL(@Parameter1, '') as varchar(100))   
      + '@Parameter3 = ''' + CAST(ISNULL(@Parameter2, '') as varchar(100))    
      + '@Parameter4 = ''' + CAST(ISNULL(@Parameter3, '') as varchar(100))  
      + '@Parameter5 = ''' + CAST(ISNULL(@Parameter4, '') as varchar(100))   
      + '@Parameter6 = ''' + CAST(ISNULL(@Count, '') as varchar(100))    
      + '@Parameter7 = ''' + CAST(ISNULL(@Idlist, '') as varchar(100))   
      + '@Parameter8 = ''' + CAST(ISNULL(@MasterCompanyId, '') as varchar(100))   
   ,@ApplicationName VARCHAR(100) = 'PAS'  
  
  -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------  
  EXEC spLogException @DatabaseName = @DatabaseName  
   ,@AdhocComments = @AdhocComments  
   ,@ProcedureParameters = @ProcedureParameters  
   ,@ApplicationName = @ApplicationName  
   ,@ErrorLogID = @ErrorLogID OUTPUT;  
  
  RAISERROR (  
    'Unexpected Error Occured in the database. Please let the support team know of the error number : %d'  
    ,16  
    ,1  
    ,@ErrorLogID  
    )  
  
  RETURN (1);  
  
END CATCH    
END
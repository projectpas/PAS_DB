/*************************************************************               
 ** File:  [usprpt_GetVendorAuditReport]      
 ** Author:  Abhishek Jirawla
 ** Description: This stored procedure is used to get Vendor Audit Report DATA.    
 ** Purpose:             
 ** Date:   18-Mar-2025
              
 ** RETURN VALUE:               
 **************************************************************               
 ** Change History               
 **************************************************************               
 ** PR   Date         Author			Change Description                
 ** --   --------     -------		--------------------------------              
    1    18-Mar-2025  Abhishek Jirawla	Created 
	2    26-Mar-2025  Abhishek Jirawla	Modification to Days Till Next Audit and Filter
         
************************************************************************/ 
CREATE      PROCEDURE [dbo].[usprpt_GetVendorAuditReport]  
@PageNumber int = 1,  
@PageSize int = NULL,  
@mastercompanyid int,  
@xmlFilter XML 
AS  
BEGIN  
  SET NOCOUNT ON;  
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
  
   DECLARE  @fromdate datetime,  
			@todate datetime, 
			@vendorname varchar(40) = NULL,
		   @ModuleID INT = 0,
		   @IsDownload BIT = NULL

			SET @IsDownload = CASE WHEN NULLIF(@PageSize,0) IS NULL THEN 1 ELSE 0 END
		  SELECT @ModuleID = (SELECT ManagementStructureModuleId FROM DBO.ManagementStructureModule WITH(NOLOCK) where ModuleName = 'EmployeeGeneralInfo');
		  BEGIN TRY  
      
	SELECT   
		 @fromdate=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='From Date'   
		 then convert(Date,filterby.value('(FieldValue/text())[1]','VARCHAR(100)')) else @fromdate end,  
		 @todate=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='To Date'   
		 then convert(Date,filterby.value('(FieldValue/text())[1]','VARCHAR(100)')) else @todate end,  
		 @vendorname=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Vendor(Optional)'   
		 then filterby.value('(FieldValue/text())[1]','VARCHAR(100)') else @vendorname end
	FROM  
		@xmlFilter.nodes('/ArrayOfFilter/Filter')AS TEMPTABLE(filterby)  
  
	IF ISNULL(@PageSize,0)=0
	BEGIN 
		SELECT @PageSize=COUNT(VAI.VendorAuditInfoId)
		FROM DBO.VendorAuditInfo VAI WITH (NOLOCK)
		WHERE VAI.VendorId = ISNULL(@vendorname, VAI.VendorId) AND VAI.mastercompanyid = @mastercompanyid and VAI.IsActive =1 AND VAI.IsDeleted=0
			AND CAST(VAI.CreatedDate AS DATE) BETWEEN CAST(@Fromdate AS DATE) AND CAST(@Todate AS DATE)
	END
  
   ;WITH rptCTE (TotalRecordsCount, VendorAuditInfoId,VendorName, VendorCode, LastAuditDate, NextAuditDate, DaysTillNextAudit, InForce, AuditFindings,
				 ActionsTaken,  PerformedBy, DatePerformed
				 ) 
				 AS (
      SELECT COUNT(1) OVER () AS TotalRecordsCount,
	   VAI.VendorAuditInfoId,
       V.VendorName,
       V.VendorCode,
	   CASE WHEN ISNULL(@IsDownload,0) = 0 THEN FORMAT(VAI.LastAuditDate, 'MM/dd/yyyy') ELSE convert(VARCHAR(50), VAI.LastAuditDate, 107) END 'LastAuditDate',
	   CASE WHEN ISNULL(@IsDownload,0) = 0 THEN FORMAT(VAI.NextAuditDate, 'MM/dd/yyyy') ELSE convert(VARCHAR(50), VAI.NextAuditDate, 107) END 'NextAuditDate',
       --VAI.FrequencyDays 'DaysTillNextAudit',
       --VAI.LastAuditDate 'InForce',
	   CASE 
			WHEN VAI.NextAuditDate IS NULL THEN '-'
			WHEN DATEDIFF(DAY, GETUTCDATE(), VAI.NextAuditDate) < 0 THEN '0'
			ELSE CAST(DATEDIFF(DAY, GETUTCDATE(), VAI.NextAuditDate) AS VARCHAR)
		END AS 'DaysTillNextAudit',
	   CASE 
			WHEN ISNULL(CAST(VAI.NextAuditDate AS DATE), '0001-01-01')  >= CAST(GETUTCDATE() AS DATE) THEN 'TRUE' 
			ELSE 'FALSE' 
		END AS 'InForce',
       ISNULL(VAI.AuditFindings, '') AS 'AuditFindings',
       ISNULL(VAI.ActionsTaken, '') AS 'ActionsTaken',
       VAI.CreatedBy 'PerformedBy',
	   CASE WHEN ISNULL(@IsDownload,0) = 0 THEN FORMAT(VAI.CreatedDate, 'MM/dd/yyyy') ELSE convert(VARCHAR(50), VAI.CreatedDate, 107) END 'DatePerformed'
      FROM DBO.VendorAuditInfo VAI WITH (NOLOCK)
		INNER JOIN DBO.Vendor V WITH (NOLOCK) ON V.vendorId = VAI.VendorId
      WHERE VAI.VendorId = ISNULL(@vendorname, VAI.VendorId) AND VAI.mastercompanyid = @mastercompanyid and VAI.IsActive =1 AND VAI.IsDeleted=0
			AND CAST(VAI.LastAuditDate AS DATE) BETWEEN CAST(@Fromdate AS DATE) AND CAST(@Todate AS DATE)  
			)
			,FinalCTE(TotalRecordsCount, VendorAuditInfoId,VendorName, VendorCode, LastAuditDate, NextAuditDate, DaysTillNextAudit, InForce, AuditFindings,
				 ActionsTaken,  PerformedBy, DatePerformed) 

			  AS (SELECT DISTINCT TotalRecordsCount, VendorAuditInfoId,VendorName, VendorCode, LastAuditDate, NextAuditDate, DaysTillNextAudit, InForce, AuditFindings,
				 ActionsTaken,  PerformedBy, DatePerformed FROM rptCTE)
			
		    SELECT COUNT(2) OVER () AS TotalRecordsCount, VendorAuditInfoId,VendorName, VendorCode, LastAuditDate, NextAuditDate, DaysTillNextAudit, InForce, AuditFindings,
				 ActionsTaken,  PerformedBy, DatePerformed
		    FROM FinalCTE FC

			ORDER BY VendorAuditInfoId DESC
		OFFSET((@PageNumber-1) * @pageSize) ROWS FETCH NEXT @pageSize ROWS ONLY; 
  END TRY  
  
  BEGIN CATCH  
   
    DECLARE @ErrorLogID int,  
            @DatabaseName varchar(100) = DB_NAME(),  
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
            @AdhocComments varchar(150) = '[usprpt_GetVendorAuditReport]',  
            @ProcedureParameters varchar(3000) = '@Parameter1 = ''' + CAST(ISNULL(@PageNumber, '') AS varchar(100)) +    
            '@Parameter2 = ''' + CAST(ISNULL(@PageSize, '') AS varchar(100)) +    
            '@Parameter3 = ''' + CAST(ISNULL(@mastercompanyid, '') AS varchar(100)) +    
            '@Parameter4 = ''' + CAST(ISNULL(@xmlFilter, '') AS varchar(max)),  
            @ApplicationName varchar(100) = 'PAS'   
    -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------  
    EXEC Splogexception @DatabaseName = @DatabaseName,  
                        @AdhocComments = @AdhocComments,  
                        @ProcedureParameters = @ProcedureParameters,  
                        @ApplicationName = @ApplicationName,  
                        @ErrorLogID = @ErrorLogID OUTPUT;  
  
    RAISERROR (  
    'Unexpected Error Occured in the database. Please let the support team know of the error number : %d'  
    , 16, 1, @ErrorLogID)  
  
    RETURN (1);  
  END CATCH   
END
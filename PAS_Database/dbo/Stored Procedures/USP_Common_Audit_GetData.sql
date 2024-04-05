/***************************************************************  
 ** File:   [USP_Common_Audit_GetData]             
 ** Author:   Vishal Suthar
 ** Description: This stored procedure is used to get Common history data
 ** Purpose:           
 ** Date:   13/06/2022  
            
  ** Change History             
 **************************************************************             
 ** PR   Date         Author		 Change Description              
 ** --   --------     -------		 --------------------------------            
    1    14/07/2022   Vishal Suthar	 Created  

-- EXEC USP_Common_Audit_GetData 'vw_ItemMasterCapesAudit',65,0
-- EXEC USP_Common_Audit_GetData 'vw_CustomerClassificationAudit',8, 0

**************************************************************/
CREATE     PROCEDURE [dbo].[USP_Common_Audit_GetData]
    @ViewName VARCHAR(100) = NULL,
	@Id INT = NULL,
	@ModuleId INT = NULL
AS
BEGIN
	DECLARE @Query1 AS VARCHAR(MAX) = '';
	DECLARE @Query2 AS VARCHAR(MAX) = '';
	
	SET @Query1 = 'SELECT COLUMN_NAME AS headerName, COLUMN_NAME AS fieldName, DATA_TYPE AS dataType FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = ''' + @ViewName + '''';
	IF(@ModuleId = 0)
	BEGIN
		SET @Query2 = 'SELECT * FROM [' + @ViewName + '] WHERE ID = ' + CAST(@Id AS VARCHAR(100)) + ' ORDER BY [PkID] DESC';
		EXEC (@Query1);
		EXEC (@Query2);
	END
	ELSE
	BEGIN
		SET @Query2 = 'SELECT * FROM [' + @ViewName + '] WHERE ID = ' + CAST(@Id AS VARCHAR(100)) + ' AND ModuleID = ' +  CAST(@ModuleId AS VARCHAR(100)) + '  ORDER BY [PkID] DESC';
		EXEC (@Query1);
		EXEC (@Query2);
	END	
END
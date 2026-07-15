
-- ---------------------------------------------------------------------------------------------------
-- Stored Procedure: dbo.USP_GetROTemplateById   (source: PAS_DB/dbo/Stored Procedures/Procs2/USP_GetROTemplateById.sql)
-- ---------------------------------------------------------------------------------------------------
/*************************************************************           
 ** File:   [USP_GetROTemplateById]           
 ** Author:   Amit Ghediya
 ** Description: This stored procedure is used to Get Ro Template records by ID
 ** Purpose:         
 ** Date:   06-05-2025       
          
 ** RETURN VALUE:           
  
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** S NO   Date            Author          Change Description              
 ** --   --------         -------          --------------------------------            
    1    06-05-2025		Amit Ghediya       Created  
	2    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0

**************************************************************/    
CREATE      PROCEDURE [dbo].[USP_GetROTemplateById]
    @RepairOrderTemplateId BIGINT
AS
BEGIN
    SET NOCOUNT ON;  
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY  
		SELECT 
		     ROT.[RepairOrderTemplateId],
	  		 ROT.ItemMasterId,
			 IM.partnumber,
			 ROT.WorkPerformedId,
			 CBT.CapabilityTypeDesc AS 'WorkToPerform',
			 ROT.CustomerId,  
			 CM.[Name] AS 'CustomerName',
			 ROT.PublicationRecordId,  
			 PUB.PublicationId,
			 ROT.VendorId, 
			 VN.VendorName,
			 ROT.Instruction,
			 ROT.[IsActive],
			 ROT.[IsDeleted],
			 ROT.[MasterCompanyId],
			 ROT.CreatedBy,
			 ROT.CreatedDate,
			 ROT.UpdatedBy,
			 ROT.UpdatedDate
		FROM [dbo].[RepairOrderTemplate] ROT WITH(NOLOCK)  
		LEFT JOIN [dbo].[ItemMaster] IM WITH(NOLOCK) ON IM.[ItemMasterId] = ROT.[ItemMasterId]
		 AND ISNULL(IM.IsNonStock,0) = 0
		 LEFT JOIN [dbo].[Customer] CM WITH(NOLOCK) ON CM.[CustomerId] = ROT.[CustomerId]
		LEFT JOIN [dbo].[Vendor] VN WITH(NOLOCK) ON VN.[VendorId] = ROT.[VendorId]
		LEFT JOIN [dbo].[Publication] PUB WITH(NOLOCK) ON PUB.[PublicationRecordId] = ROT.[PublicationRecordId]
		LEFT JOIN [dbo].[CapabilityType] CBT WITH(NOLOCK) ON CBT.[CapabilityTypeId] = ROT.[WorkPerformedId]
		WHERE ROT.RepairOrderTemplateId = @RepairOrderTemplateId;
	END TRY 
	BEGIN CATCH  
   
    DECLARE @ErrorLogID int,  
            @DatabaseName varchar(100) = DB_NAME(),  
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
            @AdhocComments varchar(150) = 'USP_GetROTemplateById',  
            @ProcedureParameters varchar(3000) = '@Parameter1 = ''' + CAST(ISNULL(@RepairOrderTemplateId, '') AS varchar(100)) +    
            '@Parameter2 = ''' + CAST(ISNULL(@RepairOrderTemplateId, '') AS varchar(100)),  
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
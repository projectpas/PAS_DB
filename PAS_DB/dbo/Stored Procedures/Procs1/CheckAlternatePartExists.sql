/*************************************************************               
 ** File:   [CheckAlternatePartExists]               
 ** Author:  SHREY CHANDEGARA    
 ** Description:  This Store Procedure use to check customer emial & phone is exists.   
 ** Purpose:             
 ** Date:   12/08/2024          
              
 ** RETURN VALUE:               
 **********************************************************               
 ** check customer emial & phone exists.             
 **********************************************************               
 ** PR   Date			Author			Change Description                
 ** --   --------		-------			--------------------------------              
    1    30/01/2025  	SHREY CHANDEGARA	Created     
 
 EXEC [CheckAlternatePartExists] 
********************************************************************/ 
CREATE   PROCEDURE [dbo].[CheckAlternatePartExists]
	@tbl_NhaTlaAlterValidateType NhaTlaAlterValidateType READONLY
AS
BEGIN
		BEGIN TRY
			
			
			
			;WITH Resutl AS (
				SELECT 
				'In this Part No : ' + IM.PartNumber + ' Already Have Alternate Part: ' + INN.PartNumber AS Result
				FROM @tbl_NhaTlaAlterValidateType t 
				JOIN [dbo].[Nha_Tla_Alt_Equ_ItemMapping] NH WITH(NOLOCK) ON NH.ItemMasterId = t.ItemMasterId AND NH.MappingItemMasterId = t.MappingItemMasterId  AND NH.MappingType = t.MappingType AND NH.MasterCompanyId = t.MasterCompanyId
				JOIN [dbo].[ItemMaster] IM WITH(NOLOCK) ON IM.ItemMasterId = NH.ItemMasterId AND IM.MasterCompanyId = NH.MasterCompanyId
				JOIN [dbo].[ItemMaster] INN WITH(NOLOCK) ON INN.ItemMasterId = NH.MappingItemMasterId AND INN.MasterCompanyId = NH.MasterCompanyId
			)

			SELECT STUFF(
					(SELECT ', ' + Result 
					 FROM Resutl 
					 FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'), 
				1, 2, ''
				) AS Message;

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				--PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'CheckAlternatePartExists' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL('', '') + ''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

              exec spLogException 
                       @DatabaseName			= @DatabaseName
                     , @AdhocComments			= @AdhocComments
                     , @ProcedureParameters		= @ProcedureParameters
                     , @ApplicationName         = @ApplicationName
                     , @ErrorLogID              = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
		END CATCH
END
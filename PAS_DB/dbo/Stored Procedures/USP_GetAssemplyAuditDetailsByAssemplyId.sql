/*************************************************************           
 ** File:   [USP_GetAssemplyAuditDetailsByAssemplyId]           
 ** Author:   BHARGAV SALIYA
 ** Description: This stored procedure is used to get Assemply history Data by AssemplyId
 ** Purpose:         
 ** Date:   22 Nov 2023      
          
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date             Author		         Change Description            
 ** --   --------         -------		     ----------------------------       
    1    22 Nov 2023   BHARGAV SALIYA               Created
    2    24 Nov 2023   BHARGAV SALIYA               Part Description issue  Resolve                          
**************************************************************/
CREATE     PROCEDURE [dbo].[USP_GetAssemplyAuditDetailsByAssemplyId]
@AssemplyId bigint
AS
BEGIN	
	    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN 
				SELECT DISTINCT
						APL.AssemplyAuditId,
						APL.AssemplyId,
						IM.ItemMasterId,
						APL.MappingItemMasterId,
						IM.Partnumber,
						IMP.Partnumber AS AltPartNo,
						IMP.PartDescription AS AltPartDescription,
						APL.Quantity,
						case when APL.PopulateWoMaterialList = 1 then 'yes' else 'no' end as PopulateWoMaterialList,
						APL.WorkScopeId,
						APL.ProvisionId,
						WS.WorkScopeCode AS WorkScope,
						PS.Description AS Provision,
						APL.Memo,
						APL.CreatedDate,
						APL.UpdatedDate,
						Upper(APL.CreatedBy) AS CreatedBy,
						Upper(APL.UpdatedBy) AS UpdatedBy,
						APL.IsActive,
						APL.IsDeleted
				FROM [dbo].[AssemplyAudit] APL WITH (NOLOCK)
				--left join [dbo].[Assemply] AP WITH (NOLOCK) ON AP.ItemMasterId = APL.ItemMasterId
				INNER JOIN [dbo].[ItemMaster] IM WITH (NOLOCK) ON IM.ItemMasterId = APL.ItemMasterId
				INNER JOIN [dbo].[ItemMaster] IMP WITH (NOLOCK) ON APL.MappingItemMasterId = IMP.ItemMasterId
				LEFT JOIN [dbo].[WorkScope] WS WITH (NOLOCK) ON WS.WorkScopeId = APL.WorkScopeId
				LEFT JOIN [dbo].[Provision] PS WITH (NOLOCK) ON PS.ProvisionId = APL.ProvisionId

				WHERE APL.AssemplyId = @AssemplyId
				ORDER BY APL.AssemplyAuditId DESC
		

	END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				--PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetAssemplyAuditDetailsByAssemplyId' 
              , @ProcedureParameters VARCHAR(3000)  = '@AssemplyId = '''+ ISNULL(@AssemplyId, '') + ''
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
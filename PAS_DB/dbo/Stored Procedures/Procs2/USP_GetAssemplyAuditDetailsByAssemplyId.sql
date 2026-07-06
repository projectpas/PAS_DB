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
	3    05/02/2025	   Ayushi Patel					converted the date into utc (created , updated) , Added a case to get timeZone
	4    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
**************************************************************/
CREATE     PROCEDURE [dbo].[USP_GetAssemplyAuditDetailsByAssemplyId]
@AssemplyId bigint,
@EmployeeId bigint
AS
BEGIN	
	    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		BEGIN TRY
		DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';
		
				SELECT 
						@CurrntEmpTimeZoneDesc = COALESCE(
							ETZ.[Description],  -- Prefer Employee's TimeZone description if available
							LTZ.[Description]   -- Fallback to LegalEntity's TimeZone description
						)
					FROM 
						dbo.Employee E WITH (NOLOCK) 
					LEFT JOIN 
						dbo.TimeZone ETZ WITH (NOLOCK) 
						ON E.TimeZoneId = ETZ.TimeZoneId
					LEFT JOIN 
						dbo.LegalEntity LE WITH (NOLOCK) 
						ON E.LegalEntityId = LE.LegalEntityId
					LEFT JOIN 
						dbo.TimeZone LTZ WITH (NOLOCK) 
						ON LE.TimeZoneId = LTZ.TimeZoneId
					WHERE 
						E.EmployeeId = @EmployeeId; -- Use appropriate filter for the specific employee
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
						--APL.CreatedDate,
						--APL.UpdatedDate,
						(Cast(DBO.ConvertUTCtoLocal(APL.CreatedDate, @CurrntEmpTimeZoneDesc) as datetime)) CreatedDate,
						(Cast(DBO.ConvertUTCtoLocal(APL.UpdatedDate, @CurrntEmpTimeZoneDesc) as datetime)) UpdatedDate,
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
				 AND ISNULL(IM.IsNonStock,0) = 0 AND ISNULL(IMP.IsNonStock,0) = 0
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
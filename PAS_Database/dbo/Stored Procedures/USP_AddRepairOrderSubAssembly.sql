/*************************************************************           
** File:  [USP_AddRepairOrderSubAssembly] 
** Author:   Bhargav Saliya
** Description: Add Repair Order Sub-Assembly
** Purpose:  
** Date:   07-28-2025  
**************************************************************           
** Change History           
**************************************************************           
** PR     Date         Author           Change Description            
** --    --------     -------           -------------------------------          
** 1     07-28-2025   Bhargav Saliya      Created  

**************************************************************/
CREATE     PROCEDURE [dbo].[USP_AddRepairOrderSubAssembly]
    @RepairOrderAssemblyId BIGINT,
    @ItemMasterId BIGINT,
    @VendorId BIGINT,
    @UnitCost DECIMAL(18,2),
    @NeedByDate DATETIME,
    @Quantity int,
    @ConditionId BIGINT,
    @ProvisionId BIGINT,
    @IsAutoCreateRo BIT,
    @MappingItemMasterId BIGINT,
	@Memo NVARCHAR(MAX),
    @MasterCompanyId BIGINT,
    @IsActive BIT,
    @IsDelete BIT,
    @CreatedBy NVARCHAR(100),
    @UpdatedBy NVARCHAR(100)
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
		IF(@RepairOrderAssemblyId = 0)  
		BEGIN  
			INSERT INTO [dbo].[RepairOrderAssembly]([ItemMasterId],[VendorId],[UnitCost],[NeedByDate],[Quantity],[ConditionId],[ProvisionId],[IsAutoCreateRo],[MappingItemMasterId],[Memo],
				  [MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted])  
		    VALUES(@ItemMasterId,@VendorId, @UnitCost,@NeedByDate,@Quantity,@ConditionId,@ProvisionId, @IsAutoCreateRo,@MappingItemMasterId,@Memo,
					@MasterCompanyId,@CreatedBy,@UpdatedBy,GETUTCDATE(),GETUTCDATE(),@IsActive,@IsDelete);  
		END  
    BEGIN TRY
	BEGIN TRANSACTION
	
	COMMIT  TRANSACTION
    END TRY
    BEGIN CATCH      
			IF @@trancount > 0
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_AddRepairOrderSubAssembly' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@RepairOrderAssemblyId, '') + ''
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
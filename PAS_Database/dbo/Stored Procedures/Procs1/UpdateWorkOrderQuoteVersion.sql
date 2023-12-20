
/*************************************************************           
 ** File:   [UpdateWorkOrderQuoteVersion]           
 ** Author:   Hemant Saliya
 ** Description: This stored procedure is used Update Work Order Quote Verion  
 ** Purpose:         
 ** Date:   05/25/2021        
          
 ** PARAMETERS:           
 @UserType varchar(60)   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    05/25/2021   Hemant Saliya Created
	2    06/25/2020   Hemant  Saliya Added Transation & Content Management
     
-- EXEC [UpdateWorkOrderQuoteVersion] 6,77,68
**************************************************************/

CREATE PROCEDURE [dbo].[UpdateWorkOrderQuoteVersion]
	@WorkOrderId BIGINT,
	@WorkOrderQuoteId BIGINT,
	@OldWorkOrderQuoteId BIGINT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

	DECLARE @WorkOrderQuoteDetailsId BIGINT;
	DECLARE @OldWorkOrderQuoteDetailsId BIGINT;
	DECLARE @WorkOrderQuoteLaborHeaderId BIGINT;
	DECLARE @OldWorkOrderQuoteLaborHeaderId BIGINT;
		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN
				SELECT @OldWorkOrderQuoteDetailsId = WorkOrderQuoteDetailsId FROM WorkOrderQuoteDetails WITH(NOLOCK) WHERE WorkOrderQuoteId = @OldWorkOrderQuoteId
				

				INSERT INTO WorkOrderQuoteDetails(
					[WorkOrderQuoteId],[ItemMasterId],[BuildMethodId],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate]
				   ,[UpdatedDate],[IsActive],[IsDeleted],[WorkflowWorkOrderId],[WOPartNoId],[MaterialCost],[MaterialBilling]
				   ,[MaterialRevenuePercentage],[MaterialMargin],[LaborHours],[LaborCost],[LaborBilling],[LaborRevenuePercentage]
				   ,[LaborMargin],[ChargesCost],[ChargesBilling],[ChargesRevenuePercentage],[ChargesMargin],[ExclusionsCost]
				   ,[ExclusionsBilling],[ExclusionsRevenuePercentage],[ExclusionsMargin],[FreightCost],[FreightBilling]
				   ,[FreightRevenuePercentage],[FreightMargin],[MaterialMarginPer],[LaborMarginPer],[ChargesMarginPer],[ExclusionsMarginPer]
				   ,[FreightMarginPer],[OverHeadCost],[AdjustmentHours],[AdjustedHours],[LaborFlatBillingAmount],[MaterialFlatBillingAmount]
				   ,[ChargesFlatBillingAmount],[FreightFlatBillingAmount],[MaterialBuildMethod],[LaborBuildMethod],[ChargesBuildMethod]
				   ,[FreightBuildMethod],[ExclusionsBuildMethod],[MaterialMarkupId],[LaborMarkupId],[ChargesMarkupId],[FreightMarkupId]
				   ,[ExclusionsMarkupId],[FreightRevenue],[LaborRevenue],[MaterialRevenue],[ExclusionsRevenue],[ChargesRevenue]
				   ,[OverHeadCostRevenuePercentage],[IsVersionIncrease])
				SELECT 
					@WorkOrderQuoteId,[ItemMasterId],[BuildMethodId],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate]
				   ,[UpdatedDate],[IsActive],[IsDeleted],[WorkflowWorkOrderId],[WOPartNoId],[MaterialCost],[MaterialBilling]
				   ,[MaterialRevenuePercentage],[MaterialMargin],[LaborHours],[LaborCost],[LaborBilling],[LaborRevenuePercentage]
				   ,[LaborMargin],[ChargesCost],[ChargesBilling],[ChargesRevenuePercentage],[ChargesMargin],[ExclusionsCost]
				   ,[ExclusionsBilling],[ExclusionsRevenuePercentage],[ExclusionsMargin],[FreightCost],[FreightBilling]
				   ,[FreightRevenuePercentage],[FreightMargin],[MaterialMarginPer],[LaborMarginPer],[ChargesMarginPer],[ExclusionsMarginPer]
				   ,[FreightMarginPer],[OverHeadCost],[AdjustmentHours],[AdjustedHours],[LaborFlatBillingAmount],[MaterialFlatBillingAmount]
				   ,[ChargesFlatBillingAmount],[FreightFlatBillingAmount],[MaterialBuildMethod],[LaborBuildMethod],[ChargesBuildMethod]
				   ,[FreightBuildMethod],[ExclusionsBuildMethod],[MaterialMarkupId],[LaborMarkupId],[ChargesMarkupId],[FreightMarkupId]
				   ,[ExclusionsMarkupId],[FreightRevenue],[LaborRevenue],[MaterialRevenue],[ExclusionsRevenue],[ChargesRevenue]
				   ,[OverHeadCostRevenuePercentage],0
				FROM WorkOrderQuoteDetails WITH(NOLOCK) WHERE WorkOrderQuoteId = @OldWorkOrderQuoteId

				SELECT @WorkOrderQuoteDetailsId = SCOPE_IDENTITY();

				UPDATE WorkOrderQuoteDetails SET IsVersionIncrease = 1 WHERE WorkOrderQuoteId = @OldWorkOrderQuoteId

				IF((SELECT COUNT(WorkOrderQuoteDetailsId) FROM [dbo].WorkOrderQuoteMaterial WITH(NOLOCK) WHERE WorkOrderQuoteDetailsId = @OldWorkOrderQuoteDetailsId) > 0)
				BEGIN
					INSERT INTO [dbo].[WorkOrderQuoteMaterial] (
						[WorkOrderQuoteDetailsId],[ItemMasterId],[ConditionCodeId],[ItemClassificationId],[Quantity],[UnitOfMeasureId]
					   ,[UnitCost],[ExtendedCost],[Memo],[IsDefered],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate]
					   ,[IsActive],[IsDeleted],[MarkupPercentageId],[TaskId],[MarkupFixedPrice],[BillingAmount],[BillingRate]
					   ,[HeaderMarkupId],[ProvisionId],[MaterialMandatoriesId],[BillingMethodId],[TaskName],[PartNumber],[PartDescription]
					   ,[Provision],[UomName],[Conditiontype],[Stocktype],[BillingName],[MarkUp])
					SELECT 
						@WorkOrderQuoteDetailsId,[ItemMasterId],[ConditionCodeId],[ItemClassificationId],[Quantity],[UnitOfMeasureId]
					   ,[UnitCost],[ExtendedCost],[Memo],[IsDefered],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate]
					   ,[IsActive],[IsDeleted],[MarkupPercentageId],[TaskId],[MarkupFixedPrice],[BillingAmount],[BillingRate]
					   ,[HeaderMarkupId],[ProvisionId],[MaterialMandatoriesId],[BillingMethodId],[TaskName],[PartNumber],[PartDescription]
					   ,[Provision],[UomName],[Conditiontype],[Stocktype],[BillingName],[MarkUp]
					FROM [dbo].[WorkOrderQuoteMaterial] WITH(NOLOCK) WHERE WorkOrderQuoteDetailsId = @OldWorkOrderQuoteDetailsId
				END
				IF((SELECT COUNT(WorkOrderQuoteDetailsId) FROM [dbo].WorkOrderQuoteCharges WITH(NOLOCK) WHERE WorkOrderQuoteDetailsId = @OldWorkOrderQuoteDetailsId) > 0)
				BEGIN
					INSERT INTO [dbo].WorkOrderQuoteCharges
						([WorkOrderQuoteDetailsId],[ChargesTypeId],[VendorId],[Quantity],[MarkupPercentageId],[Description],[UnitCost],[ExtendedCost]
					   ,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[TaskId],[MarkupFixedPrice]
					   ,[BillingAmount],[BillingRate],[HeaderMarkupId],[RefNum],[BillingMethodId],[TaskName],[ChargeType],[GlAccountName],[VendorName]
					   ,[BillingName],[MarkUp])
					SELECT 
						@WorkOrderQuoteDetailsId,[ChargesTypeId],[VendorId],[Quantity],[MarkupPercentageId],[Description],[UnitCost],[ExtendedCost]
					   ,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[TaskId],[MarkupFixedPrice]
					   ,[BillingAmount],[BillingRate],[HeaderMarkupId],[RefNum],[BillingMethodId],[TaskName],[ChargeType],[GlAccountName],[VendorName]
					   ,[BillingName],[MarkUp]
					FROM [dbo].WorkOrderQuoteCharges WITH(NOLOCK) WHERE WorkOrderQuoteDetailsId = @OldWorkOrderQuoteDetailsId
				END
				IF((SELECT COUNT(WorkOrderQuoteDetailsId) FROM [dbo].[WorkOrderQuoteFreight] WITH(NOLOCK) WHERE WorkOrderQuoteDetailsId = @OldWorkOrderQuoteDetailsId) > 0)
				BEGIN
					INSERT INTO [dbo].[WorkOrderQuoteFreight]
						([WorkOrderQuoteDetailsId],[ShipViaId],[Weight],[Memo],[Amount],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate]
					   ,[IsActive],[IsDeleted],[MarkupPercentageId],[MarkupFixedPrice],[TaskId],[HeaderMarkupId],[BillingRate],[BillingAmount],[Length]
					   ,[Width],[Height],[UOMId],[DimensionUOMId],[CurrencyId],[BillingMethodId],[TaskName],[Shipvia],[UomName],[DimensionUomName]
					   ,[Currency],[BillingName],[MarkUp])
					SELECT 
						@WorkOrderQuoteDetailsId,[ShipViaId],[Weight],[Memo],[Amount],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate]
					   ,[IsActive],[IsDeleted],[MarkupPercentageId],[MarkupFixedPrice],[TaskId],[HeaderMarkupId],[BillingRate],[BillingAmount],[Length]
					   ,[Width],[Height],[UOMId],[DimensionUOMId],[CurrencyId],[BillingMethodId],[TaskName],[Shipvia],[UomName],[DimensionUomName]
					   ,[Currency],[BillingName],[MarkUp]
					FROM [WorkOrderQuoteFreight] WITH(NOLOCK) WHERE WorkOrderQuoteDetailsId = @OldWorkOrderQuoteDetailsId
				END
				IF((SELECT COUNT(WorkOrderQuoteDetailsId) FROM [dbo].[WorkOrderQuoteLaborHeader] WITH(NOLOCK) WHERE WorkOrderQuoteDetailsId = @OldWorkOrderQuoteDetailsId) > 0)
				BEGIN
					SELECT @OldWorkOrderQuoteLaborHeaderId = WorkOrderQuoteLaborHeaderId FROM [dbo].[WorkOrderQuoteLaborHeader] WITH(NOLOCK) WHERE WorkOrderQuoteDetailsId = @OldWorkOrderQuoteDetailsId
					INSERT INTO [dbo].[WorkOrderQuoteLaborHeader]
						([WorkOrderQuoteDetailsId],[DataEnteredBy],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],
						[UpdatedDate],[IsActive],[IsDeleted],[MarkupFixedPrice],[HeaderMarkupId])
					SELECT 
						@WorkOrderQuoteDetailsId,[DataEnteredBy],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],
						[UpdatedDate],[IsActive],[IsDeleted],[MarkupFixedPrice],[HeaderMarkupId]
					FROM [dbo].[WorkOrderQuoteLaborHeader] WITH(NOLOCK) WHERE WorkOrderQuoteDetailsId = @OldWorkOrderQuoteDetailsId

					SELECT @WorkOrderQuoteLaborHeaderId = SCOPE_IDENTITY();

					INSERT INTO [dbo].[WorkOrderQuoteLabor]
						([WorkOrderQuoteLaborHeaderId],[ExpertiseId],[Hours],[BillableId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],
					    [IsActive],[IsDeleted],[TaskId],[DirectLaborOHCost],[MarkupPercentageId],[BurdenRateAmount],[TotalCostPerHour],
						[TotalCost],[BillingRate],[BillingAmount],[BurdaenRatePercentageId],[BillingMethodId],[MasterCompanyId],[TaskName],
						[Expertise],[Billabletype],[BurdaenRatePercentage],[BillingName],[MarkUp],[EmployeeId])
					SELECT 
						@WorkOrderQuoteLaborHeaderId,[ExpertiseId],[Hours],[BillableId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],
					    [IsActive],[IsDeleted],[TaskId],[DirectLaborOHCost],[MarkupPercentageId],[BurdenRateAmount],[TotalCostPerHour],
						[TotalCost],[BillingRate],[BillingAmount],[BurdaenRatePercentageId],[BillingMethodId],[MasterCompanyId],[TaskName],
						[Expertise],[Billabletype],[BurdaenRatePercentage],[BillingName],[MarkUp],[EmployeeId]
					FROM [dbo].[WorkOrderQuoteLabor] WITH(NOLOCK) WHERE WorkOrderQuoteLaborHeaderId = @OldWorkOrderQuoteLaborHeaderId
				END

			END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'UpdateWorkOrderQuoteVersion' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@WorkOrderId, '') + '''
													   @Parameter2 = '''+ ISNULL(@WorkOrderId, '') + '''
													   @Parameter3 = ' + ISNULL(@WorkOrderQuoteId ,'') +''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

              exec spLogException 
                       @DatabaseName           =  @DatabaseName
                     , @AdhocComments          =  @AdhocComments
                     , @ProcedureParameters	   =  @ProcedureParameters
                     , @ApplicationName        =  @ApplicationName
                     , @ErrorLogID             =  @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
		END CATCH
END
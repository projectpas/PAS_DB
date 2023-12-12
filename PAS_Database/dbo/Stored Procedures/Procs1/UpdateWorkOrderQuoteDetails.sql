/*************************************************************             
 ** File:   [UpdateWorkOrderQuoteDetails]             
 ** Author:   Satish Gohil
 ** Description: This stored procedure is used Add/Update WorkOrderQuote to Actual Rate   
 ** Purpose:           
 ** Date:   17/02/2023     
         
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** PR   Date         Author		Change Description              
 ** --   --------     -------		--------------------------------            
    1    17/02/2023   Satish Gohil  Created       
**************************************************************/ 
CREATE   PROCEDURE [DBO].[UpdateWorkOrderQuoteDetails]
(
	@WorkflowWorkOrderId BIGINT,
	@CommonFlatRate DECIMAL(18,2),
	@QuoteMethod BIT,
	@UpadateBy VARCHAR(50),
	@EvalFees DECIMAL(18,2)
)
AS
BEGIN 

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
SET NOCOUNT ON     

	BEGIN TRY  
		BEGIN TRANSACTION
		BEGIN 
			DECLARE @WorkOrderQuoteDetailsId BIGINT = 0;
			DECLARE @WOPartNoId BIGINT = 0; 
			DECLARE @TOTALMATERIALCOST DECIMAL(18,2) =0;
			DECLARE @TOTALMATERIALBILLINGAMT DECIMAL(18,2) =0;
			DECLARE @TOTALMATERIALEXTCOST DECIMAL(18,2) =0;	
			DECLARE @TOTALCHARGESCOST DECIMAL(18,2) =0;
			DECLARE @TOTALCHARGESBILLINGAMT DECIMAL(18,2) =0;
			DECLARE @TOTALCHRGESEXTCOST DECIMAL(18,2) =0;	
			DECLARE @TOTALFREIGHTCOST DECIMAL(18,2) =0;
			DECLARE @TOTALFREIGHTBILLINGAMT DECIMAL(18,2) =0;	
			DECLARE @TOTALLABORCOST DECIMAL(18,2) =0;
			DECLARE @TOTALLABORBILLINGAMT DECIMAL(18,2) =0;
			DECLARE @TOTALOVERHEAD DECIMAL(18,2) = 0;
			DECLARE @TOTALREVENUE DECIMAL(18,2) = 0;
			DECLARE @TOTALMARGIN DECIMAL(18,2) = 0;


			SELECT TOP 1 @WorkOrderQuoteDetailsId = WQ.WorkOrderQuoteDetailsId,@WOPartNoId = WOPartNoId 
			FROM [DBO].WorkOrderWorkFlow WF
			INNER JOIN [DBO].WorkOrderQuoteDetails WQ ON WF.WorkOrderPartNoId = WQ.WOPartNoId
			WHERE WQ.WorkFlowWorkOrderId = @WorkflowWorkOrderId

			UPDATE [DBO].WorkOrderQuoteDetails SET CommonFlatRate = @CommonFlatRate, QuoteMethod = @QuoteMethod,EvalFees = @EvalFees
			WHERE WorkOrderQuoteDetailsId = @WorkOrderQuoteDetailsId;

			UPDATE [DBO].WorkOrderQuoteMaterial SET MarkupPercentageId = NULL,HeaderMarkupId = NULL,MarkUp = NULL,
			BillingAmount =ExtendedCost, BillingRate = UnitCost,BillingMethodId = 2,BillingName= 'Actual',MarkupFixedPrice = 2,
			UpdatedBy = @UpadateBy, UpdatedDate = GETUTCDATE()
			WHERE WorkOrderQuoteDetailsId = @WorkOrderQuoteDetailsId;

			UPDATE [DBO].WorkOrderQuoteCharges SET MarkupPercentageId = NULL,HeaderMarkupId = 0,MarkUp = NULL,
			BillingAmount =ExtendedCost, BillingRate = UnitCost,BillingMethodId = 2,BillingName= 'Actual',MarkupFixedPrice = 2,
			UpdatedBy = @UpadateBy, UpdatedDate = GETUTCDATE()
			WHERE WorkOrderQuoteDetailsId = @WorkOrderQuoteDetailsId;

			UPDATE [DBO].WorkOrderQuoteFreight SET MarkupPercentageId = NULL,HeaderMarkupId = 0,MarkUp = NULL,
			BillingAmount =Amount,BillingMethodId = 2,BillingName= 'Actual',MarkupFixedPrice = 2,
			UpdatedBy = @UpadateBy, UpdatedDate = GETUTCDATE()
			WHERE WorkOrderQuoteDetailsId = @WorkOrderQuoteDetailsId;

			UPDATE [DBO].WorkOrderQuoteLabor SET MarkupPercentageId = NULL,MarkUp = NULL,
			BillingAmount =TotalCost, BillingRate = TotalCostPerHour,BillingMethodId = 2,BillingName= 'Actual',
			UpdatedBy = @UpadateBy, UpdatedDate = GETUTCDATE()
			WHERE WorkOrderQuoteLaborHeaderId = (SELECT TOP 1 WorkOrderQuoteLaborHeaderId FROM DBO.WorkOrderQuoteLaborHeader WHERE 
			WorkOrderQuoteDetailsId = @WorkOrderQuoteDetailsId);

			UPDATE [DBO].WorkOrderQuoteLaborHeader SET MarkupFixedPrice = 2,HeaderMarkupId = 0
			WHERE WorkOrderQuoteDetailsId = @WorkOrderQuoteDetailsId

			SELECT
			@TOTALMATERIALBILLINGAMT = MATERIAL.BILLINGAMOUNT,@TOTALMATERIALCOST = MATERIAL.TOTALUNITCOST, 
			@TOTALMATERIALEXTCOST = MATERIAL.TOTALEXTCOST,
			@TOTALCHARGESBILLINGAMT = CHARGES.BillingAmount,@TOTALCHARGESCOST = CHARGES.TOTALUNITCOST,
			@TOTALCHRGESEXTCOST = CHARGES.TOTALEXTCOST,
			@TOTALFREIGHTBILLINGAMT = FRIEGHT.BILLINGAMOUNT,@TOTALFREIGHTCOST =FRIEGHT.TOTALAMOUNT,
			@TOTALLABORBILLINGAMT = LABOR.BILLINGAMOUNT,@TOTALLABORCOST =LABOR.TOTALCOST,
			@TOTALOVERHEAD = LABOR.LABOROHCOST
			FROM DBO.WorkOrderQuoteDetails WQ
			OUTER APPLY (
				SELECT WW.WorkOrderQuoteDetailsId,SUM(ISNULL(wl.BillingAmount,0)) 'BILLINGAMOUNT',SUM(ISNULL(wl.TotalCost,0)) 'TOTALCOST',
				 SUM(ISNULL(wl.DirectLaborOHCost,0)) 'LABOROHCOST'
				FROM DBO.WorkOrderQuoteDetails WW
				LEFT JOIN DBO.WorkOrderQuoteLaborHeader WH ON WH.WorkOrderQuoteDetailsId = WW.WorkOrderQuoteDetailsId
				LEFT JOIN DBO.WorkOrderQuoteLabor WL ON WH.WorkOrderQuoteLaborHeaderId = WL.WorkOrderQuoteLaborHeaderId
				WHERE WW.WorkOrderQuoteDetailsId = WQ.WorkOrderQuoteDetailsId
				GROUP BY WW.WorkOrderQuoteDetailsId
			)LABOR 
			OUTER APPLY (
				SELECT WW.WorkOrderQuoteDetailsId,SUM(ISNULL(WQM.BillingAmount,0)) 'BILLINGAMOUNT', SUM(ISNULL(WQM.UnitCost,0)) 'TOTALUNITCOST', 
				SUM(ISNULL(WQM.ExtendedCost,0)) 'TOTALEXTCOST'
				FROM DBO.WorkOrderQuoteDetails WW
				LEFT JOIN DBO.WorkOrderQuoteMaterial WQM ON WQ.WorkOrderQuoteDetailsId = WQM.WorkOrderQuoteDetailsId
				WHERE WW.WorkOrderQuoteDetailsId = WQ.WorkOrderQuoteDetailsId
				GROUP BY WW.WorkOrderQuoteDetailsId
			)MATERIAL 
			OUTER APPLY (
				SELECT WW.WorkOrderQuoteDetailsId,SUM(ISNULL(WQC.BillingAmount,0)) 'BILLINGAMOUNT', SUM(ISNULL(WQC.UnitCost,0)) 'TOTALUNITCOST', 
				SUM(ISNULL(WQC.ExtendedCost,0)) 'TOTALEXTCOST'
				FROM DBO.WorkOrderQuoteDetails WW
				LEFT JOIN DBO.WorkOrderQuoteCharges WQC ON WQ.WorkOrderQuoteDetailsId = WQC.WorkOrderQuoteDetailsId
				WHERE WW.WorkOrderQuoteDetailsId = WQ.WorkOrderQuoteDetailsId
				GROUP BY WW.WorkOrderQuoteDetailsId
			)CHARGES
			OUTER APPLY (
				SELECT WW.WorkOrderQuoteDetailsId,SUM(ISNULL(WQF.BillingAmount,0)) 'BILLINGAMOUNT',
				SUM(ISNULL(WQF.Amount,0)) 'TOTALAMOUNT'
				FROM DBO.WorkOrderQuoteDetails WW
				LEFT JOIN DBO.WorkOrderQuoteFreight WQF ON WQ.WorkOrderQuoteDetailsId = WQF.WorkOrderQuoteDetailsId
				WHERE WW.WorkOrderQuoteDetailsId = WQ.WorkOrderQuoteDetailsId
				GROUP BY WW.WorkOrderQuoteDetailsId
			)FRIEGHT
			WHERE WQ.WorkOrderQuoteDetailsId = @WorkOrderQuoteDetailsId

			SET @TOTALREVENUE = @TOTALMATERIALBILLINGAMT + @TOTALCHARGESBILLINGAMT + @TOTALLABORBILLINGAMT;
			SET @TOTALMARGIN = ((@TOTALMATERIALBILLINGAMT - @TOTALMATERIALEXTCOST) + (@TOTALLABORBILLINGAMT - @TOTALLABORCOST) + (@TOTALCHARGESBILLINGAMT - @TOTALCHRGESEXTCOST));

			IF(@TOTALREVENUE > 0)
			BEGIN
				UPDATE DBO.WorkOrderQuoteDetails  SET 
				MaterialBuildMethod = 2,ChargesBuildMethod = 2,FreightBuildMethod = 2,LaborBuildMethod = 2,
				MaterialMarkupId = 0, ChargesMarkupId = 0,FreightMarkupId =0,LaborMarkupId = 0,
				MaterialMargin = (@TOTALMATERIALBILLINGAMT - @TOTALMATERIALEXTCOST),
				MaterialBilling = @TOTALMATERIALBILLINGAMT,MaterialRevenue = @TOTALMATERIALBILLINGAMT,
				MaterialCost = @TOTALMATERIALEXTCOST,
				LaborBilling = @TOTALLABORBILLINGAMT,LaborCost = @TOTALLABORCOST,
				LaborRevenue = @TOTALLABORBILLINGAMT,LaborMargin = (@TOTALLABORBILLINGAMT - @TOTALLABORCOST),
				ChargesBilling = @TOTALCHARGESBILLINGAMT,ChargesRevenue = @TOTALCHARGESBILLINGAMT,
				ChargesCost = @TOTALCHRGESEXTCOST,ChargesMargin = (@TOTALCHARGESBILLINGAMT - @TOTALCHRGESEXTCOST),
				FreightBilling = @TOTALFREIGHTBILLINGAMT ,FreightCost = @TOTALFREIGHTCOST,
				FreightRevenue = @TOTALFREIGHTBILLINGAMT, FreightMargin = (@TOTALFREIGHTBILLINGAMT - @TOTALFREIGHTCOST),
				MaterialMarginPer = ((@TOTALMARGIN / @TOTALREVENUE)* 100),MaterialRevenuePercentage = ((@TOTALMATERIALEXTCOST / @TOTALREVENUE) * 100),
				LaborMarginPer = ((@TOTALMARGIN / @TOTALREVENUE)* 100),LaborRevenuePercentage = ((@TOTALLABORCOST / @TOTALREVENUE) * 100),
				ChargesMarginPer = ((@TOTALMARGIN / @TOTALREVENUE)* 100),ChargesRevenuePercentage = ((@TOTALCHRGESEXTCOST / @TOTALREVENUE) * 100),
				OverHeadCost = @TOTALOVERHEAD,OverHeadCostRevenuePercentage = ((@TOTALOVERHEAD / @TOTALREVENUE) * 100),
				LaborFlatBillingAmount = @TOTALLABORBILLINGAMT,MaterialFlatBillingAmount = @TOTALMATERIALBILLINGAMT,
				ChargesFlatBillingAmount = @TOTALCHARGESBILLINGAMT,FreightFlatBillingAmount = @TOTALFREIGHTBILLINGAMT
				WHERE WorkOrderQuoteDetailsId = @WorkOrderQuoteDetailsId;
			END

		END
		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		 IF @@trancount > 0  
		PRINT 'ROLLBACK'  
		ROLLBACK TRAN;  
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
  
	-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
				  , @AdhocComments     VARCHAR(150)    = 'UpdateWorkOrderQuoteDetails'   
				  , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@WorkflowWorkOrderId, '') + ''',
					@Parameter2 = ' + ISNULL(@CommonFlatRate,'') + ',     
					@Parameter3 = ' + ISNULL(@QuoteMethod,'') + ',     
					@Parameter4 = ' + ISNULL(@UpadateBy,'') + ',
					@Parameter5 = ' + ISNULL(@QuoteMethod,'') + '' 
				  , @ApplicationName VARCHAR(100) = 'PAS'  
	-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------  
  
				  exec spLogException   
						   @DatabaseName           = @DatabaseName  
						 , @AdhocComments          = @AdhocComments  
						 , @ProcedureParameters = @ProcedureParameters  
						 , @ApplicationName        =  @ApplicationName  
						 , @ErrorLogID                    = @ErrorLogID OUTPUT ;  
				  RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)  
				  RETURN(1);  
	END CATCH
END
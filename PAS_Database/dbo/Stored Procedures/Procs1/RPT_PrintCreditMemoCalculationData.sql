/*************************************************************               
 ** File:   [GetCreditMemoById]               
 ** Author:  Amit Ghediya    
 ** Description: This stored procedure is used to Get Credit Memo Calculation Details    
 ** Purpose:             
 ** Date:   17/04/2023          
              
 ** PARAMETERS:     
             
 ** RETURN VALUE:               
 **************************************************************               
 ** Change History               
 **************************************************************               
 ** PR   Date         Author  Change Description                
 ** --   --------     -------  --------------------------------              
    1    17/04/2023  Amit Ghediya    Created    
    2    01/08/2023  Satish Gohil    Modify(Remove Other tax calculation )   
	3	 01/02/2024	 AMIT GHEDIYA	 added isperforma Flage for SO
	4	 04/12/2024	  HEMANT SALIYA	  Corrected Join for Getting Correct Balance

-- EXEC RPT_PrintCreditMemoCalculationData 190,1,1,546,77    
    
************************************************************************/    
CREATE   PROCEDURE [dbo].[RPT_PrintCreditMemoCalculationData]    
 @CreditMemoHeaderId bigint,    
 @MasterCompanyId BIGINT,    
 @IsWorkOrder bit,    
 @InvoicingId BIGINT,    
 @CustomerId BIGINT    
AS    
BEGIN    
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED    
 SET NOCOUNT ON;    
 BEGIN TRY    
    
	  DECLARE @tmpAwb VARCHAR(200),@ModuleID int = 61,@tmpNotes VARCHAR(MAX),     
			  @EmailTemplateTypeId BIGINT, @tmpdescription VARCHAR(MAX),@tmpTotal DECIMAL(18,2),@tmpTotalFreight DECIMAL(18,2),    
			  @tmpTotalCharges DECIMAL(18,2),@tmpSubTotals DECIMAL(18,2),@tmpCustomerId BIGINT,@tmpSiteId BIGINT,@tmpSiteTax DECIMAL(18,2),    
			  @tmpOtherSiteTax DECIMAL(18,2), @SalesTax DECIMAL(18,2), @OtherTax DECIMAL(18,2), @Freight DECIMAL(18,2), @Charges DECIMAL(18,2),
			  @SubTotal DECIMAL(18,2), @PartsRevenue DECIMAL(18,2), @LaborRevenue DECIMAL(18,2), @RestockingFee DECIMAL(18,2);    
    
	  --SEELCT AWB & NOTES    
	  SELECT     
		   @tmpAwb = (CASE WHEN CM.[IsWorkOrder]=1 THEN (SELECT ISNULL(WB.WayBillRef,NULL) FROM [dbo].[WorkOrderBillingInvoicing] WB WITH (NOLOCK)     
					   WHERE WB.[BillingInvoicingId] = CM.[InvoiceId])    
					  ELSE     
				       (SELECT TOP 1 ISNULL(SAOS.AirwayBill,NULL) FROM [dbo].[SalesOrderBillingInvoicing] SB WITH (NOLOCK)     
						LEFT JOIN SalesOrderBillingInvoicingItem SABI ON SB.SOBillingInvoicingId = SABI.SOBillingInvoicingId AND ISNULL(SABI.IsProforma,0) = 0   
						LEFT JOIN SalesOrderShipping SAOS ON SABI.SalesOrderShippingId = SAOS.SalesOrderShippingId  --and  SAOS.SalesOrderId = 192    
					   WHERE SB.[SOBillingInvoicingId] = CM.[InvoiceId] AND ISNULL(SB.[IsProforma],0) = 0 )    
				  END) ,    
		   @tmpNotes = ISNULL(CM.[Notes], ''),    
		   @tmpTotalFreight = CM.[TotalFreight],    
		   @tmpTotalCharges = CM.[TotalCharges]    
	   FROM [dbo].[CreditMemo] CM WITH (NOLOCK)     
		   INNER JOIN [dbo].[RMACreditMemoManagementStructureDetails] MS WITH (NOLOCK) ON CM.CreditMemoHeaderId = MS.ReferenceID AND MS.ModuleID = @ModuleID    
		   LEFT JOIN [dbo].[CustomerRMAHeader] CRMA ON CRMA.RMAHeaderId = CM.RMAHeaderId    
		   OUTER APPLY (SELECT TOP 1 CreditMemoDetailId FROM  CreditMemoDetails CD WITH (NOLOCK) WHERE CD.CreditMemoHeaderId = CM.CreditMemoHeaderId) CR     
	  WHERE CM.CreditMemoHeaderId = @CreditMemoHeaderId;    

	  SELECT @SalesTax = SUM(ISNULL(CMD.SalesTax, 0)), @OtherTax = SUM(ISNULL(CMD.OtherTax, 0)), @Freight =  SUM(ISNULL(CMD.FreightRevenue, 0)), @RestockingFee = SUM(ISNULL(CMD.RestockingFee, 0)),
			 @Charges =  SUM(ISNULL(CMD.MiscRevenue, 0)), @PartsRevenue = SUM(ISNULL(CMD.PartsRevenue, 0)), @LaborRevenue = SUM(ISNULL(CMD.LaborRevenue, 0))
	  FROM dbo.CreditMemoDetails CMD WITH (NOLOCK) WHERE CreditMemoHeaderId = @CreditMemoHeaderId GROUP BY CreditMemoHeaderId;
    
	  --SELECT DESCRIPTION    
	  SELECT @EmailTemplateTypeId = EmailTemplateTypeId from EmailTemplateType WHERE EmailTemplateType='CreditMemoPrintPDF';    
    
	  IF EXISTS (SELECT TOP 1 TermsConditionId FROM TermsCondition WHERE EmailTemplateTypeId = @EmailTemplateTypeId AND MasterCompanyId = @MasterCompanyId AND IsActive = 1 AND IsDeleted = 0)    
	  BEGIN    
			SELECT @tmpdescription = description     
			FROM TermsCondition WITH(NOLOCK)    
			WHERE EmailTemplateTypeId = @EmailTemplateTypeId AND MasterCompanyId = @MasterCompanyId;    
	  END    
	  ELSE    
	  BEGIN    
			SET @tmpdescription = '';    
	  END    
	     
    
	SET @SubTotal = (ISNULL(@PartsRevenue,0.00) + ISNULL(@LaborRevenue,0.00) + ISNULL(@Freight,0.00) + ISNULL(@Charges,0.00) + ISNULL(@RestockingFee,0.00));    
    
	SET @tmpTotal = (ISNULL(@SubTotal,0.00) + ISNULL(@SalesTax,0.00) + ISNULL(@OtherTax,0.00));     
    
	SELECT ISNULL(@tmpAwb,'') AS Awb, ISNULL(@tmpNotes,'') AS Notes, ISNULL(@tmpdescription,'') AS description, 
		   ISNULL(@tmpTotal,0.00) AS Total, 
		   ISNULL(@SubTotal,0.00) AS SubTotal, 
		   ISNULL(@SalesTax,0.00) AS SalesTax, 
		   ISNULL(@OtherTax,0.00) AS OtherTax, 
		   ISNULL(@Freight,0.00) AS Freight, 
		   ISNULL(@Charges,0.00) AS Charges,
		   ISNULL(@tmpTotal,0.00) AS FinalTotal
		   --ABS(@tmpTotal + (CASE WHEN ISNULL(@Freight,0.00) > 0 THEN ISNULL(@Freight,0.00) ELSE 0 END) + (CASE WHEN ISNULL(@Charges,0.00) > 0 THEN ISNULL(@Charges,0.00) ELSE 0 END)) AS FinalTotal;    
    
	END TRY        
	BEGIN CATCH          
	IF @@trancount > 0    
	PRINT 'ROLLBACK'    
	ROLLBACK TRAN;    
	DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()     
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
            , @AdhocComments     VARCHAR(150)    = 'RPT_PrintCreditMemoCalculationData'     
            , @ProcedureParameters VARCHAR(3000)  = '@CreditMemoHeaderId = '''+ ISNULL(@CreditMemoHeaderId, '') + ''    
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
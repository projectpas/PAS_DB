/*************************************************************               
 ** File:   [RPT_PrintStandAloneCreditMemoCalculationData]               
 ** Author:  Amit Ghediya    
 ** Description: This stored procedure is used to Get Stand Alone Credit Memo Calculation Details    
 ** Purpose:             
 ** Date:   13/09/2023          
              
 ** PARAMETERS:     
             
 ** RETURN VALUE:               
 **************************************************************               
 ** Change History               
 **************************************************************               
 ** PR   Date         Author		Change Description                
 ** --   --------     -------		--------------------------------              
    1    13/09/2023   Amit Ghediya    Created    

-- EXEC RPT_PrintStandAloneCreditMemoCalculationData 34,11,1,394,1969    
    
************************************************************************/    
CREATE     PROCEDURE [dbo].[RPT_PrintStandAloneCreditMemoCalculationData]    
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
  @tmpOtherSiteTax DECIMAL(18,2);    
    
  --SEELCT NOTES    
	SELECT     
		@tmpNotes = ISNULL(CM.[Notes], '')    
	FROM [dbo].[CreditMemo] CM WITH (NOLOCK)     
   WHERE CM.CreditMemoHeaderId = @CreditMemoHeaderId;    
    
  --SELECT DESCRIPTION    
  SELECT @EmailTemplateTypeId = EmailTemplateTypeId from EmailTemplateType WHERE EmailTemplateType='CreditMemoPrintPDF';    
    
  IF EXISTS (SELECT TOP 1 TermsConditionId FROM TermsCondition WHERE EmailTemplateTypeId = @EmailTemplateTypeId AND MasterCompanyId = @MasterCompanyId AND IsActive = 1 AND IsDeleted = 0)    
  BEGIN    
  SELECT @tmpdescription = description     
   FROM TermsCondition WITH(NOLOCK)    
   WHERE EmailTemplateTypeId = @EmailTemplateTypeId     
   AND MasterCompanyId = @MasterCompanyId;    
  END    
  ELSE    
  BEGIN    
   SET @tmpdescription = '';    
  END    
  
  --SELECT TOTAL    
	SELECT @tmpTotal = SUM(CM.Amount)         
		FROM dbo.StandAloneCreditMemoDetails CM WITH (NOLOCK)
	WHERE CM.CreditMemoHeaderId=@CreditMemoHeaderId AND CM.IsActive = 1 AND CM.IsDeleted = 0;
  
  SET @tmpSubTotals = (ISNULL(@tmpTotalFreight,0.00) + ISNULL(@tmpTotalCharges,0.00) + @tmpTotal);    
    
  SET @tmpTotal = (ISNULL(@tmpSubTotals,0.00) + ISNULL(@tmpSiteTax,0.00) + ISNULL(@tmpOtherSiteTax,0.00));     
    
    
  SELECT ISNULL(@tmpAwb,'') AS Awb, ISNULL(@tmpNotes,'') AS Notes, ISNULL(@tmpdescription,'') AS description, ISNULL(@tmpTotal,0.00) AS Total, ISNULL(@tmpSubTotals,0.00) AS SubTotal, ISNULL(@tmpSiteTax,0.00) AS SalesTax, ISNULL(@tmpOtherSiteTax,0.00) AS OtherTax,    
  ISNULL(@tmpTotalFreight,0.00) AS Freight, ISNULL(@tmpTotalCharges,0.00) AS Charges, @tmpTotal +(CASE WHEN @tmpTotalFreight > 0 THEN @tmpTotalFreight ELSE 0 END) + (CASE WHEN @tmpTotalCharges > 0 THEN @tmpTotalCharges ELSE 0 END) AS FinalTotal;    
    
END TRY        
 BEGIN CATCH          
  IF @@trancount > 0    
   PRINT 'ROLLBACK'    
   ROLLBACK TRAN;    
   DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()     
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
            , @AdhocComments     VARCHAR(150)    = 'RPT_PrintStandAloneCreditMemoCalculationData'     
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
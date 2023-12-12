CREATE   PROCEDURE [dbo].[USP_CreateCustomerGeneralLedger]
(
	@CustomerId BIGINT,
	@ModuleId INT,
	@ReferenceId BIGINT,
	@DocumentNumber VARCHAR(20),
	@CreditAmount DECIMAL(18,2),
	@DebitAmount DECIMAL(18,2),
	@MasterCompanyId int,
	@ModuleName VARCHAR(100),
	@CreatedBy VARCHAR(250)
)
AS
BEGIN
	BEGIN TRY
		DECLARE @AMOUNT DECIMAL(18,2) = 0;
		DECLARE @CurrentManagementStructureId BIGINT=0
		DECLARE @AccountingPeriod VARCHAR(100)
		DECLARE @AccountingPeriodId BIGINT=0

		SELECT @CurrentManagementStructureId =ManagementStructureId 
		FROM dbo.Employee WITH(NOLOCK)  
		WHERE CONCAT(TRIM(FirstName),'',TRIM(LastName)) IN (replace(@CreatedBy, ' ', '')) 
			AND MasterCompanyId=@MasterCompanyId

		SELECT TOP 1  @AccountingPeriodId=acc.AccountingCalendarId,@AccountingPeriod=PeriodName 
		FROM dbo.EntityStructureSetup est WITH(NOLOCK) 
			JOIN dbo.ManagementStructureLevel msl WITH(NOLOCK) on est.Level1Id = msl.ID 
			JOIN dbo.AccountingCalendar acc WITH(NOLOCK) on msl.LegalEntityId = acc.LegalEntityId and acc.IsDeleted =0
		WHERE est.EntityStructureId=@CurrentManagementStructureId AND acc.MasterCompanyId=@MasterCompanyId  
			AND CAST(getdate() as date) >= CAST(FromDate as date) AND  CAST(getdate() as date) <= CAST(ToDate as date)

		SELECT TOP 1 @AMOUNT = ISNULL(Amount,0) FROM DBO.CustomerGeneralLedger WITH(NOLOCK) WHERE CustomerId = @CustomerId ORDER BY CustomerGeneralLedgerId DESC

		INSERT INTO DBO.CustomerGeneralLedger(CustomerId,ModuleId,ReferenceId,DocumentNumber,CreditAmount,
			DebitAmount,Amount,ModuleName,AccountingPeriodId,AccountingPeriod,
			MasterCompanyId,CreatedBy,UpdatedBy,CreatedDate,UpdatedDate,IsActive,IsDeleted)
		VALUES(@CustomerId,@ModuleId,@ReferenceId,@DocumentNumber,@CreditAmount,@DebitAmount,
		CASE WHEN @CreditAmount > 0 THEN (@AMOUNT + ISNULL(@CreditAmount,0))
			 WHEN @DebitAmount > 0 THEN (@AMOUNT - ISNULL(@DebitAmount,0))
		     WHEN @DebitAmount = 0 AND @CreditAmount = 0 THEN (@AMOUNT)END,
			 @ModuleName,@AccountingPeriodId,@AccountingPeriod,
			 @MasterCompanyId,@CreatedBy,@CreatedBy,GETDATE(),GETDATE(),1,0)

	END TRY
	BEGIN CATCH
			PRINT 'ROLLBACK'
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'USP_CreateCustomerGeneralLedger' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@CustomerId, '') + ''
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
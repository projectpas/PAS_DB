CREATE       PROCEDURE [dbo].[USP_CustomerAlertPopup_WorkOrderStage]
@CustomerId BIGINT,
@WorkOrderStageId BIGINT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN  
				DECLARE @IsStageChange bit =0
				DECLARE @IsCustAlerts bit = 0
				DECLARE @IsEmailSent bit= 0

				 SELECT @IsStageChange= IsStageChange
					FROM [dbo].[Customer] WITH(NOLOCK) WHERE CustomerId = @CustomerId

				SELECT @IsCustAlerts= IsCustAlerts
					FROM [dbo].[WorkOrderStage] WITH(NOLOCK) WHERE WorkOrderStageId = @WorkOrderStageId


				IF(isnull(@IsStageChange,0) = 1 AND isnull(@IsCustAlerts,0) = 1)
				BEGIN
					SET @IsEmailSent = 1;
				END
				ELSE
				BEGIN
					SET @IsEmailSent = 0;
				END
				SELECT IsEmailSent=@IsEmailSent
			END
                
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				--PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_CustomerAlertPopup_WorkOrderStage' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@CustomerId, '') + '' 
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
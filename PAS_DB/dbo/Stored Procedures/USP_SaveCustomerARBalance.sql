--EXEC USP_SaveCustomerARBalance 1,10079,10079,100,150,'deep',1,'deep','deep',-1;  
CREATE   PROCEDURE [dbo].[USP_SaveCustomerARBalance]  
(  
--@CustomerCreditTermsHistoryId BIGINT,  
@AppModuleId INT,  
@ReffranceId BIGINT,  
@CustomerId BIGINT,  
@ARBalance DECIMAL(18,2),  
@Amount DECIMAL(18,2),  
@Notes VARCHAR(500),  
@MasterCompanyId INT,  
@CreatedBy VARCHAR(256),  
--@CreatedDate DATETIME,  
@UpdatedBy VARCHAR(256),  
--@UpdatedDate DATETIME,  
--@IsDeleted BIT,  
--@IsActive BIT,  
@CustomerCreditTermsHistoryId BIGINT OUTPUT  
)      
AS      
BEGIN      
  
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
SET NOCOUNT ON      
  
  BEGIN TRY  
   BEGIN TRANSACTION  
    BEGIN  
     --DECLARE @MSLevel INT;  
     --DECLARE @LastMSName VARCHAR(200);  
     --DECLARE @Query VARCHAR(MAX);  
  
     --IF OBJECT_ID(N'tempdb..#TempTable') IS NOT NULL  
     --BEGIN  
     --DROP TABLE #TempTable  
     --END  
  
     --CREATE TABLE #TempTable(LastMSName VARCHAR(MAX))  
     DECLARE @CreditLimit DECIMAL=0;  
     DECLARE @AmountDiff DECIMAL=0;  
     DECLARE @LastAmount DECIMAL=0;  
     IF(@AppModuleId = 10) --customer  
     BEGIN  
      IF EXISTS(SELECT * FROM CustomerFinancial WHERE CustomerId=@CustomerId)  
      BEGIN  
       SET @CreditLimit = (SELECT CreditLimit FROM CustomerFinancial WHERE CustomerId=@CustomerId)  
       IF(@CreditLimit > @Amount)  
       BEGIN  
        SET @AmountDiff = (ISNULL(@CreditLimit,0) - @Amount)  
        SET @ARBalance = (ISNULL(@CreditLimit,0) - @AmountDiff)  
       END  
       ELSE  
       BEGIN  
        SET @AmountDiff = (@Amount - ISNULL(@CreditLimit,0))  
        --SET @AmountDiff = (@CreditLimit - @Amount)  
        SET @ARBalance = (ISNULL(@CreditLimit,0) + @AmountDiff)  
       END  
  
       --SET @LastAmount = (SELECT TOP 1 ARBalance FROM CustomerCreditTermsHistory WHERE CustomerId=@CustomerId order by CustomerCreditTermsHistoryId desc)  
  
       INSERT INTO [dbo].[CustomerCreditTermsHistory]  
        ([AppModuleId],[ReffranceId],[CustomerId],  
        [ARBalance],[Amount],  
        [Notes],[MasterCompanyId],  
        [CreatedBy],[UpdatedBy],  
        [CreatedDate],[UpdatedDate],  
        [IsDeleted],[IsActive])  
         VALUES (@AppModuleId,@ReffranceId,@CustomerId,                       
        @ARBalance,@Amount,  
              @Notes,@MasterCompanyId,  
              @CreatedBy,@UpdatedBy,  
              GETDATE(),GETDATE(),  
              0,1)  
      END  
      ELSE  
      BEGIN  
       INSERT INTO [dbo].[CustomerCreditTermsHistory]  
        ([AppModuleId],[ReffranceId],[CustomerId],  
        [ARBalance],[Amount],  
        [Notes],[MasterCompanyId],  
        [CreatedBy],[UpdatedBy],  
        [CreatedDate],[UpdatedDate],  
        [IsDeleted],[IsActive])  
         VALUES (@AppModuleId,@ReffranceId,@CustomerId,                       
        @Amount,@Amount,  
              @Notes,@MasterCompanyId,  
              @CreatedBy,@UpdatedBy,  
              GETDATE(),GETDATE(),  
              0,1)  
      END  
     END  
     --ELSE IF(@AppModuleId = 35 OR @AppModuleId = 36)--Customer payment/receipt,credit memo---  
     ELSE IF(@AppModuleId = 41 OR @AppModuleId = 70)--Customer payment/receipt,credit memo---  
      BEGIN  
       SET @LastAmount = (SELECT TOP 1 ARBalance FROM CustomerCreditTermsHistory WHERE CustomerId=@CustomerId order by CustomerCreditTermsHistoryId desc)  
  
       INSERT INTO [dbo].[CustomerCreditTermsHistory]  
        ([AppModuleId],[ReffranceId],[CustomerId],  
        [ARBalance],[Amount],  
        [Notes],[MasterCompanyId],  
        [CreatedBy],[UpdatedBy],  
        [CreatedDate],[UpdatedDate],  
        [IsDeleted],[IsActive])  
       VALUES (@AppModuleId,@ReffranceId,@CustomerId,                       
        (ISNULL(@LastAmount,0) + @Amount),@Amount,  
              @Notes,@MasterCompanyId,  
              @CreatedBy,@UpdatedBy,  
              GETDATE(),GETDATE(),  
              0,1)  
      END  
     ELSE  
     BEGIN  
      SET @LastAmount = (SELECT TOP 1 ARBalance FROM CustomerCreditTermsHistory WHERE CustomerId=@CustomerId order by CustomerCreditTermsHistoryId desc)  
  
      IF NOT EXISTS(SELECT * FROM CustomerCreditTermsHistory WHERE [AppModuleId]=@AppModuleId and ReffranceId =@ReffranceId)  
      BEGIN  
       INSERT INTO [dbo].[CustomerCreditTermsHistory]  
         ([AppModuleId],[ReffranceId],[CustomerId],  
         [ARBalance],[Amount],  
         [Notes],[MasterCompanyId],  
         [CreatedBy],[UpdatedBy],  
         [CreatedDate],[UpdatedDate],  
         [IsDeleted],[IsActive])  
        VALUES (@AppModuleId,@ReffranceId,@CustomerId,                       
         (ISNULL(@LastAmount,0) - @Amount),@Amount,  
               @Notes,@MasterCompanyId,  
               @CreatedBy,@UpdatedBy,  
               GETDATE(),GETDATE(),  
               0,1)  
      END  
     END  
        
     SELECT @CustomerCreditTermsHistoryId = IDENT_CURRENT('CustomerCreditTermsHistory');  
  
     --IF OBJECT_ID(N'tempdb..#TempTable') IS NOT NULL  
     --BEGIN  
     --DROP TABLE #TempTable  
     --END  
  
    END  
   COMMIT  TRANSACTION  
  
  END TRY      
  BEGIN CATCH        
   IF @@trancount > 0  
    PRINT 'ROLLBACK'  
    ROLLBACK TRAN;  
    DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
  
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
              , @AdhocComments     VARCHAR(150)    = 'USP_SaveCustomerARBalance'   
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@MasterCompanyId, '') + ''  
              , @ApplicationName VARCHAR(100) = 'PAS'  
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------  
  
              exec spLogException   
                       @DatabaseName   = @DatabaseName  
                     , @AdhocComments   = @AdhocComments  
                     , @ProcedureParameters  = @ProcedureParameters  
                     , @ApplicationName   = @ApplicationName  
                     , @ErrorLogID              = @ErrorLogID OUTPUT ;  
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)  
              RETURN(1);  
  END CATCH  
END
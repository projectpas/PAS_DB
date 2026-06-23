/*************************************************************             
 ** File:   [USP_ValidateTrialBalance]             
 ** Author: Divyesh Kathiriya  
 ** Description: This stored procedure is used to Validate Trial Balance Upload Data.
 ** Purpose:           
 ** Date:   23-JUNE-2026
         
 **************************************************************             
  ** Change History             
 **************************************************************             
 S NO	Date				Author					Change Description              
 ----	-----------			-------------------		-------------------------------            
  1		23-JUNE-2026		Divyesh Kathiriya		Created  
	
**************************************************************/  

CREATE   PROCEDURE [dbo].[USP_ValidateTrialBalance]
@tbl_ValidateTrialBalanceUploadType ValidateTrialBalanceUploadType ReadOnly,
@MasterCompanyId BIGINT
AS
BEGIN
	BEGIN TRY

		DECLARE @MinId INT = 0, @TotalRecord INT = 0;
		DECLARE @Message VARCHAR(MAX);		

		IF OBJECT_ID(N'tempdb..#temptable') IS NOT NULL        
		BEGIN        
			DROP TABLE #temptable        
		END  

		CREATE TABLE #temptable      
		(      
			[RowNumber] BIGINT IDENTITY(1,1),   
			[GlAccountId] BIGINT NULL,
			[AccountCode] VARCHAR(50) NULL,
			[Debit] DECIMAL(18,6) NULL,
			[Credit] DECIMAL(18,6) NULL,
			[TransactionDate] VARCHAR(50) NULL,
			[EntryDate] VARCHAR(50) NULL,
			[Message] VARCHAR(MAX) NULL
		)  

		INSERT INTO #temptable([GlAccountId], [AccountCode], [Debit], [Credit], [TransactionDate],[EntryDate])
		SELECT ISNULL([GlAccountId],0), [AccountCode], [Debit], [Credit], [TransactionDate], [EntryDate]		
		FROM @tbl_ValidateTrialBalanceUploadType

		SELECT @TotalRecord = COUNT(*), @MinId = MIN([RowNumber]) FROM #temptable     

		WHILE @MinId <= @TotalRecord  
		BEGIN
			DECLARE @GlAccId BIGINT = 0;
			DECLARE @GlAccountId BIGINT = 0;
			DECLARE @AccountCode VARCHAR(50);
			DECLARE @DebitAmout DECIMAL(18,6) = 0;
			DECLARE @CreditAmout DECIMAL(18,6) = 0;
			DECLARE @TransactionDateText VARCHAR(50);
			DECLARE @EntryDateText VARCHAR(50);
			DECLARE @TransactionDate DATE;
			DECLARE @EntryDate DATE;
			DECLARE @EntityStructureId BIGINT = 0;
			
			IF OBJECT_ID(N'tempdb..#tmpmsg') IS NOT NULL        
			BEGIN        
				DROP TABLE #tmpmsg    
			END   

			CREATE TABLE #tmpmsg
			(        
				msg VARCHAR(100) NULL    
			) 

			SELECT @GlAccId = ISNULL([GlAccountId],0),
				   @AccountCode = [AccountCode],
				   @DebitAmout = ISNULL([Debit],0),
				   @CreditAmout = ISNULL([Credit],0),
				   @TransactionDateText = [TransactionDate],
				   @EntryDateText = [EntryDate]
			FROM #temptable WHERE [RowNumber] = @MinId             

			IF(@GlAccId > 0)
			BEGIN
				SELECT @GlAccountId = ISNULL(GLAccountId,0)				      
				  FROM [dbo].[GLAccount] WITH(NOLOCK) 
				WHERE GLAccountId = @GlAccId AND MasterCompanyId = @MasterCompanyId
				AND IsDeleted = 0 AND IsActive = 1;

				IF(ISNULL(@GlAccountId,0) = 0)
				BEGIN
					INSERT INTO #tmpmsg(msg)VALUES('GLAccount is Invalid');
				END
				ELSE
				BEGIN 
					UPDATE #temptable SET [GlAccountId] = @GlAccountId WHERE [RowNumber] = @MinId 
				END				
			END
			ELSE 
			BEGIN				
				SELECT @GlAccountId = ISNULL(GLAccountId,0)				       		
				FROM [dbo].[GLAccount] WITH(NOLOCK) 
				WHERE [AccountCode] = @AccountCode AND [MasterCompanyId] = @MasterCompanyId
				AND [IsDeleted] = 0 AND [IsActive] = 1
							
				IF(ISNULL(@GlAccountId,0) = 0)
				BEGIN
					INSERT INTO #tmpmsg(msg)VALUES('GLAccount is Invalid');
				END
				ELSE
				BEGIN 
					UPDATE #temptable SET [GlAccountId] = @GlAccountId WHERE [RowNumber] = @MinId 
				END				
			END

			IF(ISNULL(@DebitAmout,0) < 0 OR ISNULL(@CreditAmout,0) < 0)
			BEGIN
				INSERT INTO #tmpmsg(msg)VALUES('Enter Grether then 0 value in Credit or Debit.');
			END

			IF(ISNULL(@DebitAmout,0) = 0 AND ISNULL(@CreditAmout,0) = 0)
			BEGIN			
				INSERT INTO #tmpmsg(msg)VALUES('Enter Amount in Either Credit or Debit.');
			END

			SET @TransactionDateText = LTRIM(RTRIM(ISNULL(@TransactionDateText, '')));
			SET @EntryDateText = LTRIM(RTRIM(ISNULL(@EntryDateText, '')));
			SET @TransactionDate = TRY_CONVERT(DATE, @TransactionDateText, 101);
			SET @EntryDate = TRY_CONVERT(DATE, @EntryDateText, 101);

			IF(@TransactionDateText = '')
			BEGIN
				INSERT INTO #tmpmsg(msg)VALUES('Transaction Date is required.');
			END
			ELSE IF(@TransactionDateText NOT LIKE '[0-1][0-9]/[0-9][0-9]/[0-9][0-9][0-9][0-9]'
				OR @TransactionDate IS NULL)
			BEGIN
				INSERT INTO #tmpmsg(msg)VALUES('Transaction Date is must be in MM/DD/YYYY format.');
			END
			ELSE
			BEGIN
				UPDATE #temptable SET [TransactionDate] = CONVERT(VARCHAR(10), @TransactionDate, 101) WHERE [RowNumber] = @MinId;
			END

			IF(@EntryDateText = '')
			BEGIN
				INSERT INTO #tmpmsg(msg)VALUES('Entry Date is required.');
			END
			ELSE IF(@EntryDateText NOT LIKE '[0-1][0-9]/[0-9][0-9]/[0-9][0-9][0-9][0-9]'
				OR @EntryDate IS NULL)
			BEGIN
				INSERT INTO #tmpmsg(msg)VALUES('Entry Date is must be in MM/DD/YYYY format.');
			END
			ELSE
			BEGIN
				UPDATE #temptable SET [EntryDate] = CONVERT(VARCHAR(10), @EntryDate, 101) WHERE [RowNumber] = @MinId;
			END

			SELECT @Message = STUFF((SELECT DISTINCT ', ' + msg    
			FROM #tmpmsg FOR XML PATH ('')),1,1,'')    

			UPDATE #temptable SET [message] = @Message WHERE [RowNumber] = @MinId 

			SET @MinId = @MinId + 1;      
		END

		SELECT * FROM #temptable

	END TRY
	BEGIN CATCH  
  
    DECLARE @ErrorLogID int,  
            @DatabaseName varchar(100) = DB_NAME()  
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
            ,  
            @AdhocComments varchar(150) = '[USP_ValidateTrialBalance]',  
            @ProcedureParameters varchar(3000) = '@Parameter1 = ''',  
            @ApplicationName varchar(100) = 'PAS'  
  
    -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------  
    EXEC Splogexception @DatabaseName = @DatabaseName,  
                        @AdhocComments = @AdhocComments,  
                        @ProcedureParameters = @ProcedureParameters,  
                        @ApplicationName = @ApplicationName,  
                        @ErrorLogID = @ErrorLogID OUTPUT;  
  
    RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)  
  
    RETURN (1);  
  END CATCH   
END
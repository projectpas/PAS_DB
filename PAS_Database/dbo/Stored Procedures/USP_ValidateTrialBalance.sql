/*************************************************************             
 ** File:   [USP_ValidateTrialBalance]             
 ** Author: Divyesh Kathiriya  
 ** Description: This stored procedure is used to Validate Trial Balance.
 ** Purpose:           
 ** Date:   01-JUNE-2026
         
 **************************************************************             
  ** Change History             
 **************************************************************             
 S NO	Date				Author					Change Description              
 ----	-----------			-------------------		-------------------------------            
  1		01-JUNE-2026		Divyesh Kathiriya		Created  
	
**************************************************************/  

CREATE   PROCEDURE [dbo].[USP_ValidateTrialBalance]
@tbl_ValidateTrialBalanceUploadType ValidateTrialBalanceUploadType ReadOnly,
@MasterCompanyId BIGINT
AS
BEGIN
	BEGIN TRY

		DECLARE @MinId INT = 0, @TotalRecord INT = 0;
		--DECLARE @MaxLevel Int = 0;
		DECLARE @Debit DECIMAL(18,2) = 0;
		DECLARE @Credit DECIMAL(18,2) = 0;

		--DECLARE @Level1Code VARCHAR(50);
		--DECLARE @Level2Code VARCHAR(50);
		--DECLARE @Level3Code VARCHAR(50);
		--DECLARE @Level4Code VARCHAR(50);
		--DECLARE @Level5Code VARCHAR(50);
		--DECLARE @Level6Code VARCHAR(50);
		--DECLARE @Level7Code VARCHAR(50);
		--DECLARE @Level8Code VARCHAR(50);
		--DECLARE @Level9Code VARCHAR(50);
		--DECLARE @Level10Code VARCHAR(50);
		DECLARE @Message VARCHAR(MAX);
		DECLARE @Str NVARCHAR(MAX);
		DECLARE @StrCondition NVARCHAR(MAX) = '';
		IF OBJECT_ID(N'tempdb..#temptable') IS NOT NULL        
		BEGIN        
			DROP TABLE #temptable        
		END  

		CREATE TABLE #temptable      
		(      
			[RowNumber] BIGINT IDENTITY(1,1),   
			[GlAccountId] BIGINT NULL,
			[AccountCode] VARCHAR(50) NULL,
			[Debit] DECIMAL(18,2) NULL,
			[Credit] DECIMAL(18,2) NULL,
			[TransactionDate] DATETIME2 NULL,
			[EntryDate] DATETIME2 NULL,
			[Message] VARCHAR(MAX) NULL
			
			--[AccountName] VARCHAR(100) NULL,
			--[Description] VARCHAR(100) NULL,
			--[ReferenceId] [bigint] NULL,
	        --[ReferenceTypeId] [int] NULL,
			--[Name] VARCHAR(100) NULL,
			--[ManagementStructureId] BIGINT NULL,
			--[Level1Code] VARCHAR(50) NULL,
			--[Level2Code] VARCHAR(50) NULL,
			--[Level3Code] VARCHAR(50) NULL,
			--[Level4Code] VARCHAR(50) NULL,
			--[Level5Code] VARCHAR(50) NULL,
			--[Level6Code] VARCHAR(50) NULL,
			--[Level7Code] VARCHAR(50) NULL,
			--[Level8Code] VARCHAR(50) NULL,
			--[Level9Code] VARCHAR(50) NULL,
			--[Level10Code] VARCHAR(50) NULL,
			
		)        

		--INSERT INTO #temptable(GlAccountId,AccountCode,AccountName,Debit,Credit,[Description],[ReferenceId],[ReferenceTypeId],[Name],[ManagementStructureId],[Level1Code],
		--	Level2Code,Level3Code,Level4Code,Level5Code,Level6Code,Level7Code,Level8Code,Level9Code,Level10Code)
		--SELECT ISNULL(GlAccountId,0),AccountCode,AccountName,Debit,Credit,[Description],[ReferenceId],[ReferenceTypeId],[Name],0,Level1Code,
		--	Level2Code,Level3Code,Level4Code,Level5Code,Level6Code,Level7Code,Level8Code,Level9Code,Level10Code
		--FROM @tbl_ValidateTrialBalanceUploadType

		INSERT INTO #temptable([GlAccountId], [AccountCode], [Debit], [Credit], [TransactionDate],[EntryDate])
		SELECT ISNULL([GlAccountId],0), [AccountCode], [Debit], [Credit], [TransactionDate], [EntryDate]		
		FROM @tbl_ValidateTrialBalanceUploadType
		
		--SELECT @MaxLevel = [ManagementStructureLevel] FROM [dbo].[MasterCompany] WITH(NOLOCK) WHERE [MasterCompanyId] = @MasterCompanyId

SELECT * FROM #temptable

		SELECT @TotalRecord = COUNT(*), @MinId = MIN([RowNumber]) FROM #temptable     

		WHILE @MinId <= @TotalRecord  
		BEGIN
			DECLARE @GlAccId BIGINT = 0;
			DECLARE @GlAccountId BIGINT = 0;
			DECLARE @AccountCode VARCHAR(50);
			DECLARE @DebitAmout DECIMAL(18,2) = 0;
			DECLARE @CreditAmout DECIMAL(18,2) = 0;
			DECLARE @TransactionDate DATETIME2;
			DECLARE @EntryDate DATETIME2;

			DECLARE @EntityStructureId BIGINT = 0;

			--DECLARE @IsManualJEReference BIT = 0;			
			--DECLARE @GLReferenceTypeId INT = 0;	
			--DECLARE @Level1Id BIGINT = 0;
			--DECLARE @Level2Id BIGINT = 0;
			--DECLARE @Level3Id BIGINT = 0;
			--DECLARE @Level4Id BIGINT = 0;
			--DECLARE @Level5Id BIGINT = 0;
			--DECLARE @Level6Id BIGINT = 0;
			--DECLARE @Level7Id BIGINT = 0;
			--DECLARE @Level8Id BIGINT = 0;
			--DECLARE @Level9Id BIGINT = 0;
			--DECLARE @Level10Id BIGINT = 0;
			--DECLARE @ValidLevel BIT = 1;
			
			
			--DECLARE @AccountName VARCHAR(100);
			
			--DECLARE @Period VARCHAR(50);
			--DECLARE @ReferenceId BIGINT = 0;
			--DECLARE @ReferenceTypeId INT = 0;
			--DECLARE @Name VARCHAR(100);			
					

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
				   @TransactionDate = [TransactionDate],
				   @EntryDate = [EntryDate]
				   
				   --@AccountName = [AccountName],
				   --@ReferenceId = ISNULL([ReferenceId],0),
				   --@ReferenceTypeId = [ReferenceTypeId],
				   --@Name = [Name],
				   --@Period = [Period],
				   --@Level1Code = [Level1Code],
				   --@Level2Code = [Level2Code],
				   --@Level3Code = [Level3Code],
				   --@Level4Code = [Level4Code],
				   --@Level5Code = [Level5Code],
			       --@Level6Code = [Level6Code],
				   --@Level7Code = [Level7Code],
				   --@Level8Code = [Level8Code],
				   --@Level9Code = [Level9Code],
			       --@Level10Code = [Level10Code]
			  FROM #temptable WHERE [RowNumber] = @MinId 

            --IF(@Name = '')
			--BEGIN
			--	SET @Name = NULL;
			--END

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

			IF(@TransactionDate IS NULL)
			BEGIN
				INSERT INTO #tmpmsg(msg)VALUES('Transaction Date is required and must be in MM/DD/YYYY format.');
			END

			IF(@EntryDate IS NULL)
			BEGIN
				INSERT INTO #tmpmsg(msg)VALUES('Entry Date is required and must be in MM/DD/YYYY format.');
			END

			--IF(ISNULL(@MaxLevel,0) >= 1)
			--BEGIN
			--	IF(ISNULL(@Level1Code,'') = '')
			--	BEGIN				
			--		INSERT INTO #tmpmsg(msg)
			--		VALUES('Please Enter Level1Code');

			--		SET @ValidLevel = 0;
			--	END
			--	ELSE
			--	BEGIN 
			--		SELECT @Level1Id = ID FROM dbo.ManagementStructureLevel WITH(NOLOCK) 
			--		WHERE Code = @Level1Code AND MasterCompanyId = @MasterCompanyId

			--		SET @StrCondition = ' AND CAST(Level1Id AS varchar) = ' + CAST(ISNULL(@Level1Id,0) AS varchar)
			--	END
			--END			
			--IF(ISNULL(@MaxLevel,0) >= 2)
			--BEGIN
			--	IF(ISNULL(@Level2Code,'') = '')
			--	BEGIN				
			--		INSERT INTO #tmpmsg(msg)
			--		VALUES('Please Enter Level2Code');
			--		SET @ValidLevel = 0;
			--	END
			--	ELSE
			--	BEGIN 
			--		SELECT @Level2Id = ID FROM dbo.ManagementStructureLevel WITH(NOLOCK) 
			--		WHERE Code = @Level2Code AND MasterCompanyId = @MasterCompanyId

			--		SET @StrCondition = @StrCondition + ' AND CAST(Level2Id AS varchar) = ' + CAST(ISNULL(@Level2Id,0) AS varchar)
			--	END
			--END
			--IF(ISNULL(@MaxLevel,0) >= 3)
			--BEGIN
			--	IF(ISNULL(@Level3Code,'') = '')
			--	BEGIN				
			--		INSERT INTO #tmpmsg(msg)
			--		VALUES('Please Enter Level3Code');
			--		SET @ValidLevel = 0;
			--	END
			--	ELSE
			--	BEGIN 
			--		SELECT @Level3Id = ID FROM dbo.ManagementStructureLevel WITH(NOLOCK) 
			--		WHERE Code = @Level3Code AND MasterCompanyId = @MasterCompanyId

			--		SET @StrCondition =  @StrCondition +' AND CAST(Level3Id AS varchar) = ' + CAST(ISNULL(@Level3Id,0) AS varchar)
			--	END
			--END
			--IF(ISNULL(@MaxLevel,0) >= 4)
			--BEGIN
			--	IF(ISNULL(@Level4Code,'') = '')
			--	BEGIN				
			--		INSERT INTO #tmpmsg(msg)
			--		VALUES('Please Enter Level4Code');
			--		SET @ValidLevel = 0;
			--	END
			--	ELSE
			--	BEGIN 
			--		SELECT @Level4Id = ID FROM dbo.ManagementStructureLevel WITH(NOLOCK) 
			--		WHERE Code = @Level4Code AND MasterCompanyId = @MasterCompanyId

			--		SET @StrCondition =  @StrCondition +' AND CAST(Level4Id AS varchar) = ' + CAST(ISNULL(@Level4Id,0) AS varchar)
			--	END
			--END
			--IF(ISNULL(@MaxLevel,0) >= 5)
			--BEGIN
			--	IF(ISNULL(@Level5Code,'') = '')
			--	BEGIN				
			--		INSERT INTO #tmpmsg(msg)
			--		VALUES('Please Enter Level5Code');
			--		SET @ValidLevel = 0;
			--	END
			--	ELSE
			--	BEGIN 
			--		SELECT @Level5Id = ID FROM dbo.ManagementStructureLevel WITH(NOLOCK) 
			--		WHERE Code = @Level5Code AND MasterCompanyId = @MasterCompanyId

			--		SET @StrCondition =  @StrCondition +' AND CAST(Level5Id AS varchar) = ' + CAST(ISNULL(@Level5Id,0) AS varchar)
			--	END
			--END
			--IF(ISNULL(@MaxLevel,0) >= 6)
			--BEGIN
			--	IF(ISNULL(@Level6Code,'') = '')
			--	BEGIN				
			--		INSERT INTO #tmpmsg(msg)
			--		VALUES('Please Enter Level6Code');
			--		SET @ValidLevel = 0;
			--	END
			--	ELSE
			--	BEGIN 
			--		SELECT @Level6Id = ID FROM dbo.ManagementStructureLevel WITH(NOLOCK) 
			--		WHERE Code = @Level6Code AND MasterCompanyId = @MasterCompanyId

			--		SET @StrCondition =  @StrCondition +' AND CAST(Level6Id AS varchar) = ' + CAST(ISNULL(@Level6Id,0) AS varchar)
			--	END
			--END
			--IF(ISNULL(@MaxLevel,0) >= 7)
			--BEGIN
			--	IF(ISNULL(@Level7Code,'') = '')
			--	BEGIN				
			--		INSERT INTO #tmpmsg(msg)
			--		VALUES('Please Enter Level7Code');
			--		SET @ValidLevel = 0;
			--	END
			--	ELSE
			--	BEGIN 
			--		SELECT @Level7Id = ID FROM dbo.ManagementStructureLevel WITH(NOLOCK) 
			--		WHERE Code = @Level7Code AND MasterCompanyId = @MasterCompanyId

			--		SET @StrCondition =  @StrCondition +' AND CAST(Level7Id AS varchar) = ' + CAST(ISNULL(@Level7Id,0) AS varchar)
			--	END
			--END
			--IF(ISNULL(@MaxLevel,0) >= 8)
			--BEGIN
			--	IF(ISNULL(@Level8Code,'') = '')
			--	BEGIN				
			--		INSERT INTO #tmpmsg(msg)
			--		VALUES('Please Enter Level8Code');
			--		SET @ValidLevel = 0;
			--	END
			--	ELSE
			--	BEGIN 
			--		SELECT @Level8Id = ID FROM dbo.ManagementStructureLevel WITH(NOLOCK) 
			--		WHERE Code = @Level8Code AND MasterCompanyId = @MasterCompanyId

			--		SET @StrCondition =  @StrCondition +' AND CAST(Level8Id AS varchar) = ' + CAST(ISNULL(@Level8Id,0) AS varchar)
			--	END
			--END
			--IF(ISNULL(@MaxLevel,0) >= 9)
			--BEGIN
			--	IF(ISNULL(@Level9Code,'') = '')
			--	BEGIN				
			--		INSERT INTO #tmpmsg(msg)
			--		VALUES('Please Enter Level9Code');
			--		SET @ValidLevel = 0;
			--	END
			--	ELSE
			--	BEGIN 
			--		SELECT @Level9Id = ID FROM dbo.ManagementStructureLevel WITH(NOLOCK) 
			--		WHERE Code = @Level9Code AND MasterCompanyId = @MasterCompanyId

			--		SET @StrCondition =  @StrCondition +' AND CAST(Level9Id AS varchar) = ' + CAST(ISNULL(@Level9Id,0) AS varchar)
			--	END
			--END
			--IF(ISNULL(@MaxLevel,0) >= 10)
			--BEGIN
			--	IF(ISNULL(@Level10Code,'') = '')
			--	BEGIN				
			--		INSERT INTO #tmpmsg(msg)
			--		VALUES('Please Enter Level10Code');
			--		SET @ValidLevel = 0;
			--	END
			--	ELSE
			--	BEGIN 
			--		SELECT @Level10Id = ID FROM dbo.ManagementStructureLevel WITH(NOLOCK) 
			--		WHERE Code = @Level10Code AND MasterCompanyId = @MasterCompanyId

			--		SET @StrCondition =  @StrCondition + ' AND CAST(Level10Id AS varchar) = ' + CAST(ISNULL(@Level10Id,0) AS varchar)
			--	END
			--END
			
			

			--IF(@ValidLevel = 0)
			--BEGIN
			--	UPDATE #temptable SET ManagementStructureId = 0 WHERE [RowNumber] = @MinId 
			--END
			--ELSE
			--BEGIN
			--	------------ Get Management Structure Id --------------

			--	SET @Str = 'SELECT TOP 1 @EntityStructureId = ISNULL(EntityStructureId,0) FROM 
			--	dbo.EntityStructureSetup  WITH(NOLOCK) WHERE MasterCompanyId = ' + CAST(@MasterCompanyId AS Nvarchar);
			
			--	SET @Str = @Str + @StrCondition;

			--	EXEC sys.sp_executesql @Str, N'@EntityStructureId INT OUT', @EntityStructureId OUT;

			--	UPDATE #temptable SET ManagementStructureId = ISNULL(@EntityStructureId,0) WHERE [RowNumber] = @MinId 

			--	IF(ISNULL(@EntityStructureId,0) = 0)
			--	BEGIN
			--		INSERT INTO #tmpmsg(msg)
			--		VALUES('Invalid Management Structure');
			--	END
			
			--	------------ Get Management Structure Id --------------
			--END

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
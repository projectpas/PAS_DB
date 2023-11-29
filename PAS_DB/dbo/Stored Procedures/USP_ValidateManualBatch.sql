/*************************************************************             
 ** File:   [USP_ValidateManualBatch]             
 ** Author:   
 ** Description: This stored procedure is used to Validate Manual JE
 ** Purpose:           
 ** Date:   
         
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** PR   Date         Author		Change Description              
 ** --   --------     -------		-------------------------------            
	1    22/08/2023   Satish Gohil  Created
	2    31/08/2023	  Satish Gohil  Modify(Added Credit/Debit Validation and GL Validation changes)
	3    13/10/2023   MOIN BLOCH    Modify(Added Name for Customer / Vendor )
**************************************************************/  

CREATE   PROCEDURE [dbo].[USP_ValidateManualBatch]
@tbl_ManualJEUploadType ManualJEUploadType ReadOnly,
@MasterCompanyId BIGINT
AS
BEGIN
	BEGIN TRY

		DECLARE @MinId int = 0, @TotalRecord int = 0;
		DECLARE @MaxLevel Int = 0;
		DECLARE @Debit DECIMAL(18,2) = 0;
		DECLARE @Credit DECIMAL(18,2) = 0;

		DECLARE @Level1Code VARCHAR(50);
		DECLARE @Level2Code VARCHAR(50);
		DECLARE @Level3Code VARCHAR(50);
		DECLARE @Level4Code VARCHAR(50);
		DECLARE @Level5Code VARCHAR(50);
		DECLARE @Level6Code VARCHAR(50);
		DECLARE @Level7Code VARCHAR(50);
		DECLARE @Level8Code VARCHAR(50);
		DECLARE @Level9Code VARCHAR(50);
		DECLARE @Level10Code VARCHAR(50);
		DECLARE @Message VARCHAR(MAX);
		DECLARE @Str NVARCHAR(MAX);
		DECLARE @StrCondition NVARCHAR(MAX) = '';
		IF OBJECT_ID(N'tempdb..#temptable') IS NOT NULL        
		BEGIN        
			DROP TABLE #temptable        
		END  

		CREATE TABLE #temptable      
		(      
			[rownumber] BIGINT IDENTITY(1,1),   
			[GlAccountId] BIGINT NULL,
			[AccountCode] VARCHAR(50) NULL,
			[AccountName] VARCHAR(100) NULL,
			[Debit] DECIMAL(18,2) NULL,
			[Credit] DECIMAL(18,2) NULL,
			[Description] VARCHAR(100) NULL,
			[ReferenceId] [bigint] NULL,
	        [ReferenceTypeId] [int] NULL,
			[Name] VARCHAR(100) NULL,
			[ManagementStructureId] BIGINT NULL,
			[Level1Code] VARCHAR(50) NULL,
			[Level2Code] VARCHAR(50) NULL,
			[Level3Code] VARCHAR(50) NULL,
			[Level4Code] VARCHAR(50) NULL,
			[Level5Code] VARCHAR(50) NULL,
			[Level6Code] VARCHAR(50) NULL,
			[Level7Code] VARCHAR(50) NULL,
			[Level8Code] VARCHAR(50) NULL,
			[Level9Code] VARCHAR(50) NULL,
			[Level10Code] VARCHAR(50) NULL,
			[message] VARCHAR(MAX) NULL
		)        

		INSERT INTO #temptable(GlAccountId,AccountCode,AccountName,Debit,Credit,[Description],[ReferenceId],[ReferenceTypeId],[Name],[ManagementStructureId],[Level1Code],
			Level2Code,Level3Code,Level4Code,Level5Code,Level6Code,Level7Code,Level8Code,Level9Code,Level10Code)
		SELECT ISNULL(GlAccountId,0),AccountCode,AccountName,Debit,Credit,[Description],[ReferenceId],[ReferenceTypeId],[Name],0,Level1Code,
			Level2Code,Level3Code,Level4Code,Level5Code,Level6Code,Level7Code,Level8Code,Level9Code,Level10Code
		FROM @tbl_ManualJEUploadType
		
		SELECT @MaxLevel = [ManagementStructureLevel] FROM [dbo].[MasterCompany] WITH(NOLOCK) WHERE [MasterCompanyId] = @MasterCompanyId

		SELECT * FROM #temptable

		SELECT @TotalRecord = COUNT(*), @MinId = MIN(rownumber) FROM #temptable     

		WHILE @MinId <= @TotalRecord  
		BEGIN			
			DECLARE @Level1Id BIGINT = 0;
			DECLARE @Level2Id BIGINT = 0;
			DECLARE @Level3Id BIGINT = 0;
			DECLARE @Level4Id BIGINT = 0;
			DECLARE @Level5Id BIGINT = 0;
			DECLARE @Level6Id BIGINT = 0;
			DECLARE @Level7Id BIGINT = 0;
			DECLARE @Level8Id BIGINT = 0;
			DECLARE @Level9Id BIGINT = 0;
			DECLARE @Level10Id BIGINT = 0;
			DECLARE @ValidLevel BIT = 1;
			DECLARE @GlAccId BIGINT = 0;
			DECLARE @AccountCode VARCHAR(100);
			DECLARE @AccountName VARCHAR(100);
			DECLARE @GlAccountId BIGINT = 0;
			DECLARE @DebitAmout DECIMAL(18,2) = 0;
			DECLARE @CreditAmout DECIMAL(18,2) = 0;
			DECLARE @ReferenceId BIGINT = 0;
			DECLARE @ReferenceTypeId INT = 0;
			DECLARE @Name VARCHAR(100);			
			DECLARE @IsManualJEReference BIT = 0;			
			DECLARE @GLReferenceTypeId INT = 0;			

			IF OBJECT_ID(N'tempdb..#tmpmsg') IS NOT NULL        
			BEGIN        
				DROP TABLE #tmpmsg    
			END   

			CREATE TABLE #tmpmsg
			(        
				msg VARCHAR(100) NULL    
			) 

			SELECT @GlAccId = ISNULL([GLAccountId],0),
			       @AccountCode = [AccountCode],
				   @AccountName = [AccountName],
			       @Level1Code = [Level1Code],
				   @DebitAmout = ISNULL([Debit],0),
				   @CreditAmout = ISNULL([Credit],0),
				   @ReferenceId = ISNULL([ReferenceId],0),
				   @ReferenceTypeId = [ReferenceTypeId],
				   @Name = [Name],
			       @Level2Code = [Level2Code],
				   @Level3Code = [Level3Code],
				   @Level4Code = [Level4Code],
				   @Level5Code = [Level5Code],
			       @Level6Code = [Level6Code],
				   @Level7Code = [Level7Code],
				   @Level8Code = [Level8Code],
				   @Level9Code = [Level9Code],
			       @Level10Code = [Level10Code]
			  FROM #temptable WHERE rownumber = @MinId 

            IF(@Name = '')
			BEGIN
				SET @Name = NULL;
			END

			IF(@GlAccId > 0)
			BEGIN
				SELECT @GlAccountId = ISNULL(GLAccountId,0), 
				       @IsManualJEReference = [IsManualJEReference],
					   @GLReferenceTypeId = [ReferenceTypeId]
				  FROM dbo.GLAccount WITH(NOLOCK) 
				WHERE GLAccountId = @GlAccId AND MasterCompanyId = @MasterCompanyId
				AND IsDeleted = 0 AND IsActive = 1;

				IF(ISNULL(@GlAccountId,0) = 0)
				BEGIN
					INSERT INTO #tmpmsg(msg)VALUES('GLAccount is Invalid');
				END
				ELSE
				BEGIN 
					UPDATE #temptable SET [GlAccountId] = @GlAccountId WHERE rownumber = @MinId 
				END

				IF(@ReferenceId > 0 AND @ReferenceTypeId = 1)
				BEGIN
					SELECT @ReferenceId = [CustomerId] FROM [dbo].[Customer] WITH(NOLOCK) WHERE [CustomerId] = @ReferenceId AND [MasterCompanyId] = @MasterCompanyId AND [IsDeleted] = 0 AND [IsActive] = 1;
					   SET @ReferenceTypeId = @ReferenceTypeId;
					UPDATE #temptable 
					   SET [ReferenceId] = @ReferenceId,
					       [ReferenceTypeId] = @ReferenceTypeId 
					 WHERE rownumber = @MinId;
				END

				IF(@ReferenceId > 0 AND @ReferenceTypeId = 2)
				BEGIN
					SELECT @ReferenceId = [VendorId] FROM [dbo].[Vendor] WHERE [VendorId] = @ReferenceId AND [MasterCompanyId] = @MasterCompanyId AND [IsDeleted] = 0 AND [IsActive] = 1;
					  SET  @ReferenceTypeId = @ReferenceTypeId;
					  UPDATE #temptable 
					     SET [ReferenceId] = @ReferenceId,
					  	     [ReferenceTypeId] = @ReferenceTypeId 
					   WHERE rownumber = @MinId;
				END				
			END
			ELSE 
			BEGIN				
				SELECT @GlAccountId = ISNULL(GLAccountId,0),
				       @IsManualJEReference = [IsManualJEReference],
					   @GLReferenceTypeId = [ReferenceTypeId]				
				FROM [dbo].[GLAccount] WITH(NOLOCK) 
				WHERE [AccountCode] = @AccountCode AND [MasterCompanyId] = @MasterCompanyId
				AND [IsDeleted] = 0 AND [IsActive] = 1
							
				IF(ISNULL(@GlAccountId,0) = 0)
				BEGIN
					INSERT INTO #tmpmsg(msg)VALUES('GLAccount is Invalid');
				END
				ELSE
				BEGIN 
					UPDATE #temptable SET [GlAccountId] = @GlAccountId WHERE rownumber = @MinId 
				END

				IF(@GlAccountId > 0 AND @Name IS NOT NULL)
				BEGIN
					IF(@IsManualJEReference = 1 AND @GLReferenceTypeId > 0)
					BEGIN
						IF(@GLReferenceTypeId = 1)
						BEGIN							
							SELECT @ReferenceId = [CustomerId] FROM [dbo].[Customer] WITH(NOLOCK) WHERE UPPER([Name]) = UPPER(@Name) AND [MasterCompanyId] = @MasterCompanyId AND [IsDeleted] = 0 AND [IsActive] = 1;
							SET @ReferenceTypeId = @GLReferenceTypeId;

							IF(ISNULL(@ReferenceId,0) = 0)
							BEGIN
								INSERT INTO #tmpmsg(msg)VALUES('Customer is Invalid');
							END
							ELSE
							BEGIN 
								UPDATE #temptable 
							      SET [ReferenceId] = @ReferenceId,
							          [ReferenceTypeId] = @ReferenceTypeId 
						        WHERE rownumber = @MinId 
							END
							
						END
						IF(@GLReferenceTypeId = 2)
						BEGIN							
							SELECT @ReferenceId = [VendorId] FROM [dbo].[Vendor] WHERE UPPER(VendorName) = UPPER(@Name) AND [MasterCompanyId] = @MasterCompanyId AND [IsDeleted] = 0 AND [IsActive] = 1;
							SET @ReferenceTypeId = @GLReferenceTypeId;
							IF(ISNULL(@ReferenceId,0) = 0)
							BEGIN
								INSERT INTO #tmpmsg(msg)VALUES('Vendor is Invalid');
							END
							ELSE
							BEGIN 
								UPDATE #temptable 
								  SET [ReferenceId] = @ReferenceId,
									  [ReferenceTypeId] = @ReferenceTypeId 
								WHERE rownumber = @MinId 
							END
						END						
					END
					ELSE
					BEGIN
						INSERT INTO #tmpmsg(msg)VALUES('Allow Manual JE in GLAccount');
					END					
				END				
			END		



			IF(ISNULL(@DebitAmout,0) < 0 OR ISNULL(@CreditAmout,0) < 0)
			BEGIN
				INSERT INTO #tmpmsg(msg)VALUES('Enter Grether then 0 value in Credit or Debit');
			END
			IF(ISNULL(@DebitAmout,0) = 0 AND ISNULL(@CreditAmout,0) = 0)
			BEGIN			
				INSERT INTO #tmpmsg(msg)VALUES('Enter Amount in Either Credit or Debit');
			END
			IF(ISNULL(@MaxLevel,0) >= 1)
			BEGIN
				IF(ISNULL(@Level1Code,'') = '')
				BEGIN				
					INSERT INTO #tmpmsg(msg)
					VALUES('Please Enter Level1Code');

					SET @ValidLevel = 0;
				END
				ELSE
				BEGIN 
					SELECT @Level1Id = ID FROM dbo.ManagementStructureLevel WITH(NOLOCK) 
					WHERE Code = @Level1Code AND MasterCompanyId = @MasterCompanyId

					SET @StrCondition = ' AND CAST(Level1Id AS varchar) = ' + CAST(ISNULL(@Level1Id,0) AS varchar)
				END
			END			
			IF(ISNULL(@MaxLevel,0) >= 2)
			BEGIN
				IF(ISNULL(@Level2Code,'') = '')
				BEGIN				
					INSERT INTO #tmpmsg(msg)
					VALUES('Please Enter Level2Code');
					SET @ValidLevel = 0;
				END
				ELSE
				BEGIN 
					SELECT @Level2Id = ID FROM dbo.ManagementStructureLevel WITH(NOLOCK) 
					WHERE Code = @Level2Code AND MasterCompanyId = @MasterCompanyId

					SET @StrCondition = @StrCondition + ' AND CAST(Level2Id AS varchar) = ' + CAST(ISNULL(@Level2Id,0) AS varchar)
				END
			END
			IF(ISNULL(@MaxLevel,0) >= 3)
			BEGIN
				IF(ISNULL(@Level3Code,'') = '')
				BEGIN				
					INSERT INTO #tmpmsg(msg)
					VALUES('Please Enter Level3Code');
					SET @ValidLevel = 0;
				END
				ELSE
				BEGIN 
					SELECT @Level3Id = ID FROM dbo.ManagementStructureLevel WITH(NOLOCK) 
					WHERE Code = @Level3Code AND MasterCompanyId = @MasterCompanyId

					SET @StrCondition =  @StrCondition +' AND CAST(Level3Id AS varchar) = ' + CAST(ISNULL(@Level3Id,0) AS varchar)
				END
			END
			IF(ISNULL(@MaxLevel,0) >= 4)
			BEGIN
				IF(ISNULL(@Level4Code,'') = '')
				BEGIN				
					INSERT INTO #tmpmsg(msg)
					VALUES('Please Enter Level4Code');
					SET @ValidLevel = 0;
				END
				ELSE
				BEGIN 
					SELECT @Level4Id = ID FROM dbo.ManagementStructureLevel WITH(NOLOCK) 
					WHERE Code = @Level4Code AND MasterCompanyId = @MasterCompanyId

					SET @StrCondition =  @StrCondition +' AND CAST(Level4Id AS varchar) = ' + CAST(ISNULL(@Level4Id,0) AS varchar)
				END
			END
			IF(ISNULL(@MaxLevel,0) >= 5)
			BEGIN
				IF(ISNULL(@Level5Code,'') = '')
				BEGIN				
					INSERT INTO #tmpmsg(msg)
					VALUES('Please Enter Level5Code');
					SET @ValidLevel = 0;
				END
				ELSE
				BEGIN 
					SELECT @Level5Id = ID FROM dbo.ManagementStructureLevel WITH(NOLOCK) 
					WHERE Code = @Level5Code AND MasterCompanyId = @MasterCompanyId

					SET @StrCondition =  @StrCondition +' AND CAST(Level5Id AS varchar) = ' + CAST(ISNULL(@Level5Id,0) AS varchar)
				END
			END
			IF(ISNULL(@MaxLevel,0) >= 6)
			BEGIN
				IF(ISNULL(@Level6Code,'') = '')
				BEGIN				
					INSERT INTO #tmpmsg(msg)
					VALUES('Please Enter Level6Code');
					SET @ValidLevel = 0;
				END
				ELSE
				BEGIN 
					SELECT @Level6Id = ID FROM dbo.ManagementStructureLevel WITH(NOLOCK) 
					WHERE Code = @Level6Code AND MasterCompanyId = @MasterCompanyId

					SET @StrCondition =  @StrCondition +' AND CAST(Level6Id AS varchar) = ' + CAST(ISNULL(@Level6Id,0) AS varchar)
				END
			END
			IF(ISNULL(@MaxLevel,0) >= 7)
			BEGIN
				IF(ISNULL(@Level7Code,'') = '')
				BEGIN				
					INSERT INTO #tmpmsg(msg)
					VALUES('Please Enter Level7Code');
					SET @ValidLevel = 0;
				END
				ELSE
				BEGIN 
					SELECT @Level7Id = ID FROM dbo.ManagementStructureLevel WITH(NOLOCK) 
					WHERE Code = @Level7Code AND MasterCompanyId = @MasterCompanyId

					SET @StrCondition =  @StrCondition +' AND CAST(Level7Id AS varchar) = ' + CAST(ISNULL(@Level7Id,0) AS varchar)
				END
			END
			IF(ISNULL(@MaxLevel,0) >= 8)
			BEGIN
				IF(ISNULL(@Level8Code,'') = '')
				BEGIN				
					INSERT INTO #tmpmsg(msg)
					VALUES('Please Enter Level8Code');
					SET @ValidLevel = 0;
				END
				ELSE
				BEGIN 
					SELECT @Level8Id = ID FROM dbo.ManagementStructureLevel WITH(NOLOCK) 
					WHERE Code = @Level8Code AND MasterCompanyId = @MasterCompanyId

					SET @StrCondition =  @StrCondition +' AND CAST(Level8Id AS varchar) = ' + CAST(ISNULL(@Level8Id,0) AS varchar)
				END
			END
			IF(ISNULL(@MaxLevel,0) >= 9)
			BEGIN
				IF(ISNULL(@Level9Code,'') = '')
				BEGIN				
					INSERT INTO #tmpmsg(msg)
					VALUES('Please Enter Level9Code');
					SET @ValidLevel = 0;
				END
				ELSE
				BEGIN 
					SELECT @Level9Id = ID FROM dbo.ManagementStructureLevel WITH(NOLOCK) 
					WHERE Code = @Level9Code AND MasterCompanyId = @MasterCompanyId

					SET @StrCondition =  @StrCondition +' AND CAST(Level9Id AS varchar) = ' + CAST(ISNULL(@Level9Id,0) AS varchar)
				END
			END
			IF(ISNULL(@MaxLevel,0) >= 10)
			BEGIN
				IF(ISNULL(@Level10Code,'') = '')
				BEGIN				
					INSERT INTO #tmpmsg(msg)
					VALUES('Please Enter Level10Code');
					SET @ValidLevel = 0;
				END
				ELSE
				BEGIN 
					SELECT @Level10Id = ID FROM dbo.ManagementStructureLevel WITH(NOLOCK) 
					WHERE Code = @Level10Code AND MasterCompanyId = @MasterCompanyId

					SET @StrCondition =  @StrCondition + ' AND CAST(Level10Id AS varchar) = ' + CAST(ISNULL(@Level10Id,0) AS varchar)
				END
			END
			
			DECLARE @EntityStructureId BIGINT = 0;

			IF(@ValidLevel = 0)
			BEGIN
				UPDATE #temptable SET ManagementStructureId = 0 WHERE rownumber = @MinId 
			END
			ELSE
			BEGIN
				------------ Get Management Structure Id --------------

					SET @Str = 'SELECT TOP 1 @EntityStructureId = ISNULL(EntityStructureId,0) FROM 
					dbo.EntityStructureSetup WHERE MasterCompanyId = ' + CAST(@MasterCompanyId AS Nvarchar)
			
					SET @Str = @Str + @StrCondition

					PRINT (@Str);

					EXEC sys.sp_executesql @Str, N'@EntityStructureId INT OUT', @EntityStructureId OUT;

					UPDATE #temptable SET ManagementStructureId = ISNULL(@EntityStructureId,0) WHERE rownumber = @MinId 

					IF(ISNULL(@EntityStructureId,0) = 0)
					BEGIN
						INSERT INTO #tmpmsg(msg)
						VALUES('Invalid Management Structure');
					END
			
				------------ Get Management Structure Id --------------
			END

			SELECT @Message = STUFF((SELECT DISTINCT ', ' + msg    
			FROM #tmpmsg FOR XML PATH ('')),1,1,'')    

			UPDATE #temptable SET [message] = @Message WHERE rownumber = @MinId 

			SET @MinId = @MinId + 1;      
		END

		SELECT * FROM #temptable

	END TRY
	BEGIN CATCH
	END CATCH
END
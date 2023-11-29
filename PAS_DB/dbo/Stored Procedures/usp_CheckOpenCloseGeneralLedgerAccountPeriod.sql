/*************************************************************           
 ** File:     [usp_CheckOpenCloseGeneralLedgerAccountPeriod]           
 ** Author:	   Moin Bloch
 ** Description: This SP is Used to Validate Open/Close General Ledger

 ** Purpose:         
 ** Date:   09/22/2023
          
 ** PARAMETERS:             
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------     
	1    09/22/2023   Moin Bloch		Created

**************************************************************/ 
CREATE   PROCEDURE [dbo].[usp_CheckOpenCloseGeneralLedgerAccountPeriod]
@tbl_AccountPeriodType AccountPeriodType READONLY,
@MasterCompanyId int
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
		BEGIN TRY
		--BEGIN TRANSACTION
		--BEGIN
			DECLARE @InsertedWorkOrderMaterialsKitMappingId BIGINT;
			DECLARE @Main_LoopID AS INT;
			DECLARE @LoopID AS INT;
			DECLARE @UpdatedBy varchar(50)
	        DECLARE @periodName varchar(50)

			DECLARE @AccountsReceivablesAccountType varchar(50) = 'AR';
			DECLARE @AccountPayableAccountType varchar(50) = 'AP';
			DECLARE @InventoryAccountType varchar(50) = 'INV';
			DECLARE @FixedAssetAccountType varchar(50) = 'ASSET';
			DECLARE @GeneralLedgerAccountType varchar(50) = 'GEN';
			
			IF OBJECT_ID(N'tempdb..#AccountPeriodType') IS NOT NULL
			BEGIN
				DROP TABLE #AccountPeriodType 
			END

			IF OBJECT_ID(N'tempdb..#ValidateOpenCloseGeneralLedger') IS NOT NULL
			BEGIN
				DROP TABLE #ValidateOpenCloseGeneralLedger 
			END
			
			CREATE TABLE #AccountPeriodType 
			(
				ID BIGINT NOT NULL IDENTITY, 
				[ACCReferenceId] [bigint] NULL,
				[ACPReferenceId] [bigint] NULL,
				[ACRReferenceId] [bigint] NULL,
				[AssetReferenceId] [bigint] NULL,
				[InventoryReferenceId] [bigint] NULL,
				[IsACCStatusName] bit NULL,
				[IsACPStatusName] bit NULL,
				[IsACRStatusName] bit NULL,
				[IsAssetStatusName] bit NULL,
				[IsInventoryStatusName] bit NULL,
				[UpdatedBy] [varchar](256) NULL,
				[PeriodName] [varchar](256) NULL
			)

			CREATE TABLE #ValidateOpenCloseGeneralLedger 
			(						
				[Message] [varchar](256) NULL				
			)			
				
			INSERT INTO #AccountPeriodType 
			(ACCReferenceId, [ACPReferenceId], [ACRReferenceId], [AssetReferenceId], [InventoryReferenceId], [IsACCStatusName], [IsACPStatusName], [IsACRStatusName], 
			[IsAssetStatusName], [IsInventoryStatusName], UpdatedBy, [PeriodName])
			SELECT ACCReferenceId, [ACPReferenceId], [ACRReferenceId], [AssetReferenceId], [InventoryReferenceId], [IsACCStatusName], [IsACPStatusName], [IsACRStatusName], 
			[IsAssetStatusName], [IsInventoryStatusName], UpdatedBy, [PeriodName]
			FROM @tbl_AccountPeriodType

			DECLARE @TotMainCount AS INT;
			SELECT @TotMainCount = COUNT(*), @Main_LoopID = MIN(ID) FROM #AccountPeriodType;

			WHILE (@Main_LoopID <= @TotMainCount)
			BEGIN
				DECLARE @IsACCStatusName bit;
				DECLARE @IsACPStatusName bit;
				DECLARE @IsACRStatusName bit;
				DECLARE @IsAssetStatusName bit;
				DECLARE @IsInventoryStatusName bit;

				DECLARE @IsACCStatusNameold bit;
				DECLARE @IsACPStatusNameold bit;
				DECLARE @IsACRStatusNameold bit;
				DECLARE @IsAssetStatusNameold bit;
				DECLARE @IsInventoryStatusNameold bit;

				DECLARE @ACCReferenceId bigint;
				DECLARE @ACPReferenceId bigint;
				DECLARE @ACRReferenceId bigint;
				DECLARE @AssetReferenceId bigint;
				DECLARE @InventoryReferenceId bigint;
				DECLARE @LegalEntityId bigint;
				DECLARE @LegalEntity varchar(50);
				SELECT @ACCReferenceId = ACCReferenceId,
				       @ACPReferenceId = ACPReferenceId,
					   @ACRReferenceId = ACRReferenceId,
					   @AssetReferenceId = AssetReferenceId,
					   @InventoryReferenceId = InventoryReferenceId,
					   @IsACCStatusName = ISNULL(IsACCStatusName,0),
					   @IsACPStatusName = ISNULL(IsACPStatusName,0),
				       @IsACRStatusName = ISNULL(IsACRStatusName,0),
					   @IsAssetStatusName = ISNULL(IsAssetStatusName,0),
					   @IsInventoryStatusName = ISNULL(IsInventoryStatusName,0),
					   @UpdatedBy = UpdatedBy,
					   @periodName = PeriodName 
				  FROM #AccountPeriodType WHERE ID = @Main_LoopID;

				--SELECT * FROM #AccountPeriodType WHERE ID = @Main_LoopID;

			    SELECT @IsACRStatusNameold = ISNULL(AC.IsACRStatusName,0),
				       @IsACPStatusNameold = ISNULL(AC.IsACPStatusName,0), 
					   @IsInventoryStatusNameold = ISNULL(AC.IsInventoryStatusName,0),
					   @IsAssetStatusNameold = ISNULL(AC.IsAssetStatusName,0),
					   @IsACCStatusNameold = ISNULL(AC.IsACCStatusName,0),				
					   @MasterCompanyId = AC.MasterCompanyId,
					   @LegalEntityId = ISNULL(AC.LegalEntityId,0), 
					   @LegalEntity = LE.[Name]
				  FROM [dbo].[AccountingCalendar] AC WITH(NOLOCK)
				  LEFT JOIN [dbo].[LegalEntity] LE WITH(NOLOCK) ON AC.[LegalEntityId] = LE.[LegalEntityId]				  
				  WHERE [AccountingCalendarId] = @ACCReferenceId;
				  
                DECLARE @TotalDebit DECIMAL(18,2) = 0;
				DECLARE @TotalCredit DECIMAL(18,2) = 0;

				IF(@IsACRStatusName != @IsACRStatusNameold)
				BEGIN
					IF(@IsACRStatusName = 0)
					BEGIN
						SET @TotalDebit = 0;
						SET @TotalCredit = 0;

						SELECT @TotalDebit = ISNULL(SUM(ISNULL(TOTALDEBIT,0)),0), 
							   @TotalCredit = ISNULL(SUM(ISNULL(TOTALCREDIT,0)),0)
						  FROM [dbo].[BatchHeader] WITH(NOLOCK)
						 WHERE [AccountingPeriodId] IN (SELECT [AccountingCalendarId] FROM [dbo].[AccountingCalendar] WITH(NOLOCK) WHERE [PeriodName] = @periodName AND [LegalEntityId] = @LegalEntityId) AND 
			                   [JournalTypeId] IN(SELECT ID FROM dbo.JournalType WITH(NOLOCK) WHERE [BatchType] = @AccountsReceivablesAccountType)
			               AND [MasterCompanyId] = @MasterCompanyId;	
							 				
						PRINT 	@LegalEntityId		
						PRINT 	@TotalDebit		
						PRINT 	@TotalCredit		

						 IF(@TotalDebit <> @TotalCredit)
						 BEGIN
							INSERT INTO #ValidateOpenCloseGeneralLedger([Message])
							VALUES('Accounts Receivable	Total Credit and Debit is Mismatch For ' + @LegalEntity + ' Total Credit: '+ CONVERT(VARCHAR,CONVERT(DECIMAL(18,2),@TotalCredit)) + ' Total Debit: '+ CONVERT(VARCHAR,CONVERT(DECIMAL(18,2),@TotalDebit))) 
						 END
					END					
				END
				IF(@IsACPStatusName != @IsACPStatusNameold)
				BEGIN
					IF(@IsACPStatusName = 0)
					BEGIN
						SET @TotalDebit = 0;
						SET @TotalCredit = 0;

						SELECT @TotalDebit = ISNULL(SUM(ISNULL(TOTALDEBIT,0)),0), 
							   @TotalCredit = ISNULL(SUM(ISNULL(TOTALCREDIT,0)),0)
						  FROM [dbo].[BatchHeader] WITH(NOLOCK)
						 WHERE [AccountingPeriodId] IN (SELECT [AccountingCalendarId] FROM [dbo].[AccountingCalendar] WITH(NOLOCK) WHERE [PeriodName] = @periodName AND [LegalEntityId] = @LegalEntityId) AND 
			                   [JournalTypeId] IN(SELECT ID FROM dbo.JournalType WITH(NOLOCK) WHERE [BatchType] = @AccountPayableAccountType)
			               AND [MasterCompanyId] = @MasterCompanyId;	

						PRINT 	@LegalEntityId		
						PRINT 	@TotalDebit		
						PRINT 	@TotalCredit		

						
						IF(@TotalDebit <> @TotalCredit)
						BEGIN
							INSERT INTO #ValidateOpenCloseGeneralLedger([Message])
							VALUES('Account Payable	Total Credit and Debit is Mismatch For ' + @LegalEntity + ' Total Credit: '+ CONVERT(VARCHAR,CONVERT(DECIMAL(18,2),@TotalCredit)) + ' Total Debit: '+ CONVERT(VARCHAR,CONVERT(DECIMAL(18,2),@TotalDebit))) 
						END
					END		
				END
				IF(@IsInventoryStatusName != @IsInventoryStatusNameold)
				BEGIN
					IF(@IsInventoryStatusName = 0)
					BEGIN
						SET @TotalDebit = 0;
						SET @TotalCredit = 0;

						SELECT @TotalDebit = ISNULL(SUM(ISNULL(TOTALDEBIT,0)),0), 
							   @TotalCredit = ISNULL(SUM(ISNULL(TOTALCREDIT,0)),0)
						  FROM [dbo].[BatchHeader] WITH(NOLOCK)
						 WHERE [AccountingPeriodId] IN (SELECT [AccountingCalendarId] FROM [dbo].[AccountingCalendar] WITH(NOLOCK) WHERE [PeriodName] = @periodName AND [LegalEntityId] = @LegalEntityId) AND 
			                   [JournalTypeId] IN(SELECT ID FROM dbo.JournalType WITH(NOLOCK) WHERE [BatchType] = @InventoryAccountType)
			               AND [MasterCompanyId] = @MasterCompanyId;
						   
						PRINT 	@LegalEntityId		
						PRINT 	@TotalDebit		
						PRINT 	@TotalCredit	
						   							
						IF(@TotalDebit <> @TotalCredit)
						BEGIN
							INSERT INTO #ValidateOpenCloseGeneralLedger([Message])
							VALUES('Inventory Total Credit and Debit is Mismatch For ' + @LegalEntity + ' Total Credit: '+ CONVERT(VARCHAR,CONVERT(DECIMAL(18,2),@TotalCredit)) + ' Total Debit: '+ CONVERT(VARCHAR,CONVERT(DECIMAL(18,2),@TotalDebit))) 
						END
					END						
				END
				IF(@IsAssetStatusName != @IsAssetStatusNameold)
				BEGIN									
					IF(@IsAssetStatusName = 0)
					BEGIN
						SELECT @TotalDebit = ISNULL(SUM(ISNULL(TOTALDEBIT,0)),0), 
							   @TotalCredit = ISNULL(SUM(ISNULL(TOTALCREDIT,0)),0)
						  FROM [dbo].[BatchHeader] WITH(NOLOCK)
						 WHERE [AccountingPeriodId] IN (SELECT [AccountingCalendarId] FROM [dbo].[AccountingCalendar] WITH(NOLOCK) WHERE [PeriodName] = @periodName AND [LegalEntityId] = @LegalEntityId) AND 
			                   [JournalTypeId] IN(SELECT ID FROM dbo.JournalType WITH(NOLOCK) WHERE [BatchType] = @FixedAssetAccountType)
			               AND [MasterCompanyId] = @MasterCompanyId;	

						IF(@TotalDebit <> @TotalCredit)
						BEGIN
							INSERT INTO #ValidateOpenCloseGeneralLedger([Message])
							VALUES('Asset Total Credit and Debit is Mismatch For ' + @LegalEntity + ' Total Credit: '+ CONVERT(VARCHAR,CONVERT(DECIMAL(18,2),@TotalCredit)) + ' Total Debit: '+ CONVERT(VARCHAR,CONVERT(DECIMAL(18,2),@TotalDebit))) 
						END
					END	
				END
				IF(@IsACCStatusName != @IsACCStatusNameold)
				BEGIN
					IF(@IsACCStatusName = 0)
					BEGIN
						SET @TotalDebit = 0;
						SET @TotalCredit = 0;

						SELECT @TotalDebit = ISNULL(SUM(ISNULL(TOTALDEBIT,0)),0), 
							   @TotalCredit = ISNULL(SUM(ISNULL(TOTALCREDIT,0)),0)
						  FROM [dbo].[BatchHeader] WITH(NOLOCK)
						 WHERE [AccountingPeriodId] IN (SELECT [AccountingCalendarId] FROM [dbo].[AccountingCalendar] WITH(NOLOCK) WHERE [PeriodName] = @periodName AND [LegalEntityId] = @LegalEntityId)  
			               AND [MasterCompanyId] = @MasterCompanyId;	
							 								
						IF(@TotalDebit <> @TotalCredit)
						BEGIN
							INSERT INTO #ValidateOpenCloseGeneralLedger([Message])
							VALUES('General Ledger Total Credit and Debit is Mismatch For ' + @LegalEntity + ' Total Credit: '+ CONVERT(VARCHAR,CONVERT(DECIMAL(18,2),@TotalCredit)) + ' Total Debit: '+ CONVERT(VARCHAR,CONVERT(DECIMAL(18,2),@TotalDebit))) 
						END
					END							
				END
				SET @Main_LoopID = @Main_LoopID + 1;
			END
			SELECT * FROM #ValidateOpenCloseGeneralLedger;
		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'                  
              DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'usp_CheckOpenCloseGeneralLedgerAccountPeriod' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''
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
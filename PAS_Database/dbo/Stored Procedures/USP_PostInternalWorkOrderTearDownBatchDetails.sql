/*************************************************************           
 ** File:   [USP_PostInternalWorkOrderTearDownBatchDetails]           
 ** Author: Moin Bloch
 ** Description: This stored procedure is used insert Internal Work Order - Teardown  detail in batch
 ** Purpose:         
 ** Date:  26/03/2024

 ** PARAMETERS:           
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date				 Author					Change Description            
 ** --   --------			-------				--------------------------------          
	1    26/03/2024          Moin Bloch          Created
	2    04/04/2024          Moin Bloch          changed logic for unit cost
	3    12/04/2024          Devendra Shekh      added case to set @ManagementStructureId  
     
    EXEC USP_PostInternalWorkOrderTearDownBatchDetails 3731,3222
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_PostInternalWorkOrderTearDownBatchDetails]
@WorkOrderId BIGINT,
@WorkOrderPartNoId BIGINT
AS
BEGIN 
	BEGIN TRY
		DECLARE @CodeTypeId AS BIGINT = 74;
		DECLARE @MasterCompanyId BIGINT=0;   
		DECLARE @UpdateBy VARCHAR(100);
		DECLARE @currentNo AS BIGINT = 0;
		DECLARE @JournalTypeNumber VARCHAR(100);
		DECLARE @DistributionMasterId BIGINT;    
		DECLARE @DistributionCode VARCHAR(200); 
		DECLARE @CurrentManagementStructureId BIGINT=0; 
		DECLARE @StatusId INT;    
		DECLARE @StatusName VARCHAR(200);    
		DECLARE @AccountingPeriod VARCHAR(100);    
		DECLARE @AccountingPeriodId BIGINT=0;   
		DECLARE @JournalTypeId INT;    
		DECLARE @JournalTypeCode VARCHAR(200);
		DECLARE @JournalBatchHeaderId BIGINT;    
		DECLARE @JournalTypename VARCHAR(200);  
		DECLARE @batch VARCHAR(100);    
		DECLARE @Currentbatch VARCHAR(100);    
		DECLARE @CurrentNumber INT;    
		DECLARE @Amount DECIMAL(18,2)=0; 
		DECLARE @CurrentPeriodId BIGINT=0; 
		DECLARE @LineNumber INT=1;    
		DECLARE @JournalBatchDetailId BIGINT=0;
		DECLARE @CommonBatchDetailId BIGINT=0;
		DECLARE @DistributionSetupId INT=0
		DECLARE @Distributionname VARCHAR(200) 
		DECLARE @GlAccountId INT
		DECLARE @GlAccountName VARCHAR(200) 
		DECLARE @GlAccountNumber VARCHAR(200) 
		DECLARE @ManagementStructureId BIGINT
		DECLARE @LastMSLevel VARCHAR(200)
		DECLARE @AllMSlevels VARCHAR(max)
		DECLARE @ModuleId INT
		DECLARE @TotalDebit DECIMAL(18, 2) =0;
		DECLARE @TotalCredit DECIMAL(18, 2) =0;
		DECLARE @TotalBalance DECIMAL(18, 2) =0;
		DECLARE @VendorName VARCHAR(50);
		DECLARE @CRDRType BIGINT = 0;		
		DECLARE @WorkOrderNumber VARCHAR(200);
		DECLARE @ItemmasterId bigint
	    DECLARE @CustRefNumber varchar(200)
		DECLARE @MPNName varchar(200) 
		DECLARE @CustomerId bigint
	    DECLARE @CustomerName varchar(200)		
		DECLARE @AccountMSModuleId INT = 0
		DECLARE @UnitCost DECIMAL(18, 2) =0;
		DECLARE @WorkOrderTypeId INT=0;
		DECLARE @TeardownType INT=0;		

		SELECT @AccountMSModuleId = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE [ModuleName] ='Accounting';

		SELECT @TeardownType = [Id] FROM [dbo].[WorkOrderType] WITH(NOLOCK) WHERE [Description] ='Teardown';

		IF OBJECT_ID(N'tempdb..#tmpCodePrefixes') IS NOT NULL
		BEGIN
			DROP TABLE #tmpCodePrefixes
		END
					  	  
		CREATE TABLE #tmpCodePrefixes
		(
			[ID] BIGINT NOT NULL IDENTITY, 
			[CodePrefixId] BIGINT NULL,
			[CodeTypeId] BIGINT NULL,
			[CurrentNumber] BIGINT NULL,
			[CodePrefix] VARCHAR(50) NULL,
			[CodeSufix] VARCHAR(50) NULL,
			[StartsFrom] BIGINT NULL,
		)    
		
		-- Only Tear Down WO Type Batch Entry
			
		SELECT @UnitCost = ((ISNULL(WOP.StocklineCost,0) + ISNULL(WOPC.PartsCost,0) + ISNULL(WOPC.LaborCost,0) + ISNULL(WOPC.OtherCost,0)) - ISNULL(wop.TendorStocklineCost,0)),
               @WorkOrderTypeId = WO.[WorkOrderTypeId]     
            FROM [dbo].[WorkOrder] WO WITH(NOLOCK)			   
			INNER JOIN [dbo].[WorkOrderPartNumber] WOP WITH(NOLOCK) ON WO.[WorkOrderId] = WOP.WorkOrderId  
             LEFT JOIN [dbo].[WorkOrderMPNCostDetails] WOPC WITH(NOLOCK) ON WOP.ID = WOPC.WOPartNoId
            INNER JOIN [dbo].[Stockline]  SL WITH(NOLOCK) ON WOP.StockLineId=SL.StockLineId               
            WHERE WOP.ID = @WorkOrderPartNoId;

		SELECT @WorkOrderNumber = wo.WorkOrderNum,
			   @CustomerId=CustomerId,
			   @CustomerName= CustomerName 
			FROM [dbo].[WorkOrder] wo WITH(NOLOCK) WHERE [WorkOrderId] = @WorkOrderId;
		
		IF(ISNULL(@UnitCost,0) > 0 AND @WorkOrderTypeId = @TeardownType)
		BEGIN
			IF(NOT EXISTS (SELECT 1 FROM dbo.WorkOrderBatchDetails WHERE [ReferenceId] = @WorkOrderId AND [MPNPartId] = @WorkOrderPartNoId AND [UnitPrice] = @UnitCost AND [ReferenceName] = @WorkOrderNumber ))
			BEGIN 

		    SELECT @MasterCompanyId = [MasterCompanyId], @UpdateBy = [CreatedBy],@CurrentManagementStructureId = [ManagementStructureId] FROM [dbo].[WorkOrderPartNumber] WITH(NOLOCK) WHERE [WorkOrderId] = @WorkOrderId AND [ID] = @WorkOrderPartNoId;			
			SELECT @DistributionMasterId = [ID] FROM [dbo].[DistributionMaster] WITH(NOLOCK) WHERE UPPER([DistributionCode]) = UPPER('InternalWorkOrderTeardown');
			SELECT @StatusId = [Id],@StatusName = [name] FROM [dbo].[BatchStatus] WITH(NOLOCK) WHERE UPPER([Name]) = UPPER('Open');
			SELECT TOP 1 @JournalTypeId = [JournalTypeId] FROM [dbo].[DistributionSetup] WITH(NOLOCK) WHERE [DistributionMasterId] = @DistributionMasterId;
			SELECT @JournalBatchHeaderId = [JournalBatchHeaderId] FROM [dbo].[BatchHeader] WITH(NOLOCK) WHERE [JournalTypeId] = @JournalTypeId AND [StatusId] = @StatusId;
			SELECT @JournalTypeCode = [JournalTypeCode],@JournalTypename = [JournalTypeName] FROM [dbo].[JournalType] WITH(NOLOCK) WHERE [ID] = @JournalTypeId;						
		   		   
		    SELECT @ModuleId = (SELECT [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE [ModuleName] ='WorkOrderMPN');
				
			SET @ManagementStructureId = CASE WHEN ISNULL(@ManagementStructureId, 0) = 0 THEN @CurrentManagementStructureId ELSE @ManagementStructureId END;
		    SELECT @LastMSLevel = LastMSLevel,
			       @AllMSlevels = AllMSlevels 
			  FROM [dbo].[WorkOrderManagementStructureDetails] WITH(NOLOCK) 
			 WHERE [EntityMSID] = @ManagementStructureId 
			   AND [ModuleID] =  @ModuleId
			   AND [ReferenceID] = @WorkOrderPartNoId;

			SELECT @ItemmasterId = WOP.[ItemMasterId], 
				   @CustRefNumber = WOP.[CustomerReference],	
				   @MPNName  = partnumber 
			  FROM [dbo].[WorkOrderPartNumber] WOP WITH(NOLOCK) 	
			  INNER JOIN [dbo].[ItemMaster] ITM WITH(NOLOCK) ON WOP.ItemMasterId = ITM.ItemMasterId 
			  WHERE WOP.[WorkOrderId] = @WorkOrderId 
			    AND WOP.[ID] = @WorkOrderPartNoId;
			
			INSERT INTO #tmpCodePrefixes 
			      ([CodePrefixId],
				   [CodeTypeId],
				   [CurrentNumber],
				   [CodePrefix],
				   [CodeSufix],
				   [StartsFrom]) 
		 SELECT CP.[CodePrefixId], 
			    CP.[CodeTypeId], 
				CP.[CurrentNummber], 
				CP.[CodePrefix], 
				CP.[CodeSufix], 
				CP.[StartsFrom]
			FROM [dbo].[CodePrefixes] CP WITH(NOLOCK) 
			JOIN [dbo].[CodeTypes] CT WITH(NOLOCK) ON CP.[CodeTypeId] = CT.[CodeTypeId]
			WHERE CT.CodeTypeId IN (@CodeTypeId) 
			  AND CP.[MasterCompanyId] = @MasterCompanyId 
			  AND CP.[IsActive] = 1 
			  AND CP.[IsDeleted] = 0;
			  		
			SELECT TOP 1  @AccountingPeriodId = acc.[AccountingCalendarId],
			              @AccountingPeriod = [PeriodName] 
			         FROM [dbo].[EntityStructureSetup] est WITH(NOLOCK) 
			   INNER JOIN [dbo].[ManagementStructureLevel] msl WITH(NOLOCK) ON est.Level1Id = msl.ID 
			   INNER JOIN [dbo].[AccountingCalendar] acc WITH(NOLOCK) ON msl.LegalEntityId = acc.LegalEntityId AND acc.IsDeleted =0
			    WHERE est.[EntityStructureId] = @CurrentManagementStructureId 
			      AND acc.[MasterCompanyId] = @MasterCompanyId  
			      AND CAST(GETUTCDATE() AS DATE) >= CAST([FromDate] AS DATE) 
			      AND CAST(GETUTCDATE() AS DATE) <= CAST([ToDate] AS DATE)

			IF(EXISTS (SELECT 1 FROM #tmpCodePrefixes WHERE [CodeTypeId] = @CodeTypeId))
			BEGIN 
				SELECT @currentNo = CASE WHEN [CurrentNumber] > 0 THEN CAST([CurrentNumber] AS BIGINT) + 1 ELSE CAST([StartsFrom] AS BIGINT) + 1 END 
				  FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId
					  	  
				SET @JournalTypeNumber = (SELECT * FROM dbo.udfGenerateCodeNumber(@currentNo,(SELECT CodePrefix FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId), (SELECT CodeSufix FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId)))
			END
			ELSE 
			BEGIN
				ROLLBACK TRAN;
			END
			
			IF NOT EXISTS(SELECT [JournalBatchHeaderId] FROM [dbo].[BatchHeader] WITH(NOLOCK) WHERE [JournalTypeId] = @JournalTypeId AND [MasterCompanyId]=@MasterCompanyId AND CAST([EntryDate] AS DATE) = CAST(GETUTCDATE() AS DATE) AND [StatusId]=@StatusId)
			BEGIN
				IF NOT EXISTS(SELECT [JournalBatchHeaderId] FROM [dbo].[BatchHeader] WITH(NOLOCK))
				BEGIN  
					SET @batch ='001'  
					SET @Currentbatch='001' 
				END
				ELSE
				BEGIN 
					SELECT TOP 1 @Currentbatch = CASE WHEN CurrentNumber > 0 THEN CAST(CurrentNumber AS BIGINT) + 1 ELSE  1 END   
					  FROM [dbo].[BatchHeader] WITH(NOLOCK) ORDER BY JournalBatchHeaderId desc  

					IF(CAST(@Currentbatch AS BIGINT) >99)  
					BEGIN
						SET @batch = CASE WHEN CAST(@Currentbatch AS BIGINT) > 99 THEN CAST(@Currentbatch AS VARCHAR(100))  
						                  ELSE CONCAT('00', CAST(@Currentbatch AS VARCHAR(50))) 
									  END   
					END  
					ELSE IF(CAST(@Currentbatch AS BIGINT) >9)  
					BEGIN    
						SET @batch = CASE WHEN CAST(@Currentbatch AS BIGINT) > 99 THEN CAST(@Currentbatch AS VARCHAR(100))  
						                  ELSE CONCAT('0', CAST(@Currentbatch AS VARCHAR(50))) 
									  END   
					END
					ELSE
					BEGIN
					    SET @batch = CASE WHEN CAST(@Currentbatch AS BIGINT) > 99 THEN CAST(@Currentbatch AS VARCHAR(100))  
						                  ELSE CONCAT('00', CAST(@Currentbatch AS VARCHAR(50))) 
									  END     
					END  
				END
			
				SET @CurrentNumber = CAST(@Currentbatch AS BIGINT)    
				
				SET @batch = CAST(@JournalTypeCode +' '+ CAST(@batch AS VARCHAR(100)) AS VARCHAR(100))  

				INSERT INTO [dbo].[BatchHeader]    
				           ([BatchName],
						    [CurrentNumber],
							[EntryDate],
							[AccountingPeriod],
							[AccountingPeriodId],
							[StatusId],[StatusName],
				            [JournalTypeId],
							[JournalTypeName],
							[TotalDebit],
							[TotalCredit],
							[TotalBalance],
							[MasterCompanyId],
				            [CreatedBy],
							[UpdatedBy],
							[CreatedDate],
							[UpdatedDate],
							[IsActive],
							[IsDeleted],
							[Module])    
				     VALUES    
				           (@batch,
						    @CurrentNumber,
							GETUTCDATE(),
							@AccountingPeriod,
							@AccountingPeriodId,
							@StatusId,
							@StatusName,
				            @JournalTypeId,
							@JournalTypename,
							@Amount,
							@Amount,
							0,
							@MasterCompanyId,
				            @UpdateBy,
							@UpdateBy,
							GETUTCDATE(),
							GETUTCDATE(),
							1,
							0,
							@JournalTypeCode);    
                           
				SELECT @JournalBatchHeaderId = SCOPE_IDENTITY();   
				
				UPDATE [dbo].[BatchHeader] SET [CurrentNumber] = @CurrentNumber WHERE [JournalBatchHeaderId] = @JournalBatchHeaderId;  
			END
			ELSE
			BEGIN 
				SELECT @JournalBatchHeaderId = [JournalBatchHeaderId],@CurrentPeriodId = ISNULL([AccountingPeriodId],0) FROM [dbo].[BatchHeader] WITH(NOLOCK) WHERE [JournalTypeId]= @JournalTypeId AND [StatusId]=@StatusId   
				SELECT @LineNumber = CASE WHEN [LineNumber] > 0 THEN CAST([LineNumber] AS BIGINT) + 1 ELSE  1 END   
				  FROM [dbo].[BatchDetails] WITH(NOLOCK) 
				 WHERE [JournalBatchHeaderId] = @JournalBatchHeaderId 
				 ORDER BY [JournalBatchDetailId] DESC   
          
				IF(@CurrentPeriodId =0)  
				BEGIN  
				   UPDATE [dbo].[BatchHeader] SET [AccountingPeriodId]=@AccountingPeriodId,[AccountingPeriod]=@AccountingPeriod WHERE [JournalBatchHeaderId] = @JournalBatchHeaderId  
				END  
			END

			INSERT INTO [dbo].[BatchDetails]
			           ([JournalTypeNumber],
					    [CurrentNumber],
						[DistributionSetupId],
						[DistributionName],
						[JournalBatchHeaderId], 
						[LineNumber], 
						[GlAccountId], 
						[GlAccountNumber], 
						[GlAccountName], 
			            [TransactionDate], 
						[EntryDate], 
						[JournalTypeId], 
						[JournalTypeName], 
						[IsDebit], 
						[DebitAmount], 
						[CreditAmount], 
						[ManagementStructureId], 
						[ModuleName], 
						[LastMSLevel], 
						[AllMSlevels], 
						[MasterCompanyId], 
			            [CreatedBy], 
						[UpdatedBy], 
						[CreatedDate], 
						[UpdatedDate], 
						[IsActive], 
						[IsDeleted],
						[AccountingPeriodId],
						[AccountingPeriod])
			     VALUES(@JournalTypeNumber,
				        @currentNo,
						0, 
						NULL, 
						@JournalBatchHeaderId, 
						1, 
						0, 
						NULL, 
						NULL, 
						GETUTCDATE(), 
						GETUTCDATE(), 
			            @JournalTypeId, 
						@JournalTypename, 
						1, 
						0, 
						0, 
						@ManagementStructureId, 
						'InternalWorkOrderTeardown', 
			            @LastMSLevel, 
						@AllMSlevels, 
						@MasterCompanyId, 
						@UpdateBy, 
						@UpdateBy, 
						GETUTCDATE(), 
						GETUTCDATE(), 
						1, 
						0,
						@AccountingPeriodId,
						@AccountingPeriod)
		
			SET @JournalBatchDetailId = SCOPE_IDENTITY()

			 -----COGS/INVENTORY RESERVE--------

			SELECT TOP 1 @DistributionSetupId = [ID],
			             @DistributionName = [Name],
						 @JournalTypeId = [JournalTypeId], 
						 @CRDRType = [CRDRType],
			             @GlAccountId = [GlAccountId],
						 @GlAccountNumber = [GlAccountNumber],
						 @GlAccountName = [GlAccountName] 
			        FROM [dbo].[DistributionSetup] WITH(NOLOCK) WHERE UPPER([DistributionSetupCode]) = UPPER('IWOTCOGSINVENTORYRESERVE') 
			         AND [DistributionMasterId] = @DistributionMasterId;
					 
			INSERT INTO [dbo].[CommonBatchDetails]
				        ([JournalBatchDetailId],
						 [JournalTypeNumber],
						 [CurrentNumber],
						 [DistributionSetupId],
						 [DistributionName],
						 [JournalBatchHeaderId],
						 [LineNumber],
				         [GlAccountId],
						 [GlAccountNumber],
						 [GlAccountName],
						 [TransactionDate],
						 [EntryDate],
						 [JournalTypeId],
						 [JournalTypeName],
				         [IsDebit],
						 [DebitAmount],
						 [CreditAmount],
						 [ManagementStructureId],
						 [ModuleName],
						 [LastMSLevel],
						 [AllMSlevels],
						 [MasterCompanyId],
				         [CreatedBy],
						 [UpdatedBy],
						 [CreatedDate],
						 [UpdatedDate],
						 [IsActive],
						 [IsDeleted])
				  VALUES	
				        (@JournalBatchDetailId,
						 @JournalTypeNumber,
						 @currentNo,
						 @DistributionSetupId,
						 @DistributionName,
						 @JournalBatchHeaderId,
						 1, 
				         @GlAccountId,
						 @GlAccountNumber,
						 @GlAccountName,
						 GETUTCDATE(),
						 GETUTCDATE(),
						 @JournalTypeId,
						 @JournalTypename,
						 CASE WHEN @CRDRType = 1 THEN 1 ELSE 0 END,
						 CASE WHEN @CRDRType = 1 THEN @UnitCost ELSE 0 END,
						 CASE WHEN @CRDRType = 1 THEN 0 ELSE @UnitCost END,				
				         @ManagementStructureId,
						 'InternalWorkOrderTeardown',
						 @LastMSLevel,
						 @AllMSlevels,
						 @MasterCompanyId,
				         @UpdateBy,
						 @UpdateBy,
						 GETUTCDATE(),
						 GETUTCDATE(),
						 1,
						 0)

			SET @CommonBatchDetailId = SCOPE_IDENTITY()

			-----  Accounting MS Entry  -----

			EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 
			
			INSERT INTO [dbo].[WorkOrderBatchDetails]
			           ([JournalBatchDetailId],
					    [JournalBatchHeaderId],
						[ReferenceId],
						[ReferenceName],
						[MPNPartId],
						[MPNName],
						[PiecePNId],
						[PiecePN],
						[CustomerId],
						[CustomerName] ,
						[InvoiceId],
						[InvoiceName],
						[ARControlNum] ,
						[CustRefNumber] ,
						[Qty],
						[UnitPrice],
						[LaborHrs],
						[DirectLaborCost],
						[OverheadCost],
						[CommonJournalBatchDetailId],
						[StocklineId],
						[StocklineNumber],
						[IsWorkOrder])
				VALUES (@JournalBatchDetailId,
				        @JournalBatchHeaderId,
						@WorkOrderId,
						@WorkOrderNumber,
						@WorkOrderPartNoId,
						@MPNName,
						NULL,
						NULL,
						@CustomerId ,
						@CustomerName,
						NULL,
						NULL,
						NULL,
						@CustRefNumber,
						NULL,
						@UnitCost,
						NULL,
						NULL,
						NULL,
						@CommonBatchDetailId,
						NULL,
						NULL,
						1)

			 -----INVENTORY--------
			 				
			 SELECT TOP 1 @DistributionSetupId = [ID],
			              @DistributionName = [Name],
						  @JournalTypeId = [JournalTypeId], 
						  @CRDRType = [CRDRType],
			              @GlAccountId = [GlAccountId],
						  @GlAccountNumber = [GlAccountNumber],
						  @GlAccountName = [GlAccountName] 
			         FROM [dbo].[DistributionSetup] WITH(NOLOCK)					
					WHERE UPPER([DistributionSetupCode]) = UPPER('IWOTINVENTORY')
			          AND [DistributionMasterId] = @DistributionMasterId;

			 INSERT INTO [dbo].[CommonBatchDetails]
				        ([JournalBatchDetailId],
						 [JournalTypeNumber],
						 [CurrentNumber],
						 [DistributionSetupId],
						 [DistributionName],
						 [JournalBatchHeaderId],
						 [LineNumber],
				         [GlAccountId],
						 [GlAccountNumber],
						 [GlAccountName],
						 [TransactionDate],
						 [EntryDate],
						 [JournalTypeId],
						 [JournalTypeName],
				         [IsDebit],
						 [DebitAmount],
						 [CreditAmount],
						 [ManagementStructureId],
						 [ModuleName],
						 [LastMSLevel],
						 [AllMSlevels],
						 [MasterCompanyId],
				         [CreatedBy],
						 [UpdatedBy],
						 [CreatedDate],
						 [UpdatedDate],
						 [IsActive],
						 [IsDeleted])
				  VALUES	
				        (@JournalBatchDetailId,
						 @JournalTypeNumber,
						 @currentNo,
						 @DistributionSetupId,
						 @DistributionName,
						 @JournalBatchHeaderId,
						 1,
						 @GlAccountId,
						 @GlAccountNumber,
						 @GlAccountName,
						 GETUTCDATE(),
						 GETUTCDATE(),
						 @JournalTypeId,
						 @JournalTypename,				
				         CASE WHEN @CRDRType = 1 THEN 1 ELSE 0 END,
						 CASE WHEN @CRDRType = 1 THEN @UnitCost ELSE 0 END,
						 CASE WHEN @CRDRType = 1 THEN 0 ELSE @UnitCost END,	
				         @ManagementStructureId,
						 'InternalWorkOrderTeardown',
						 @LastMSLevel,
						 @AllMSlevels,
						 @MasterCompanyId,
				         @UpdateBy,
						 @UpdateBy,
						 GETUTCDATE(),
						 GETUTCDATE(),
						 1,
						 0)

			 SET @CommonBatchDetailId = SCOPE_IDENTITY()

			-----  Accounting MS Entry  -----

			EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @CommonBatchDetailId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@AccountMSModuleId,1; 
			
			INSERT INTO [dbo].[WorkOrderBatchDetails]
			           ([JournalBatchDetailId],
					    [JournalBatchHeaderId],
						[ReferenceId],
						[ReferenceName],
						[MPNPartId],
						[MPNName],
						[PiecePNId],
						[PiecePN],
						[CustomerId],
						[CustomerName] ,
						[InvoiceId],
						[InvoiceName],
						[ARControlNum] ,
						[CustRefNumber] ,
						[Qty],
						[UnitPrice],
						[LaborHrs],
						[DirectLaborCost],
						[OverheadCost],
						[CommonJournalBatchDetailId],
						[StocklineId],
						[StocklineNumber],
						[IsWorkOrder])
				VALUES (@JournalBatchDetailId,
				        @JournalBatchHeaderId,
						@WorkOrderId,
						@WorkOrderNumber,
						@WorkOrderPartNoId,
						@MPNName,
						NULL,
						NULL,
						@CustomerId ,
						@CustomerName,
						NULL,
						NULL,
						NULL,
						@CustRefNumber,
						NULL,
						@UnitCost,
						NULL,
						NULL,
						NULL,
						@CommonBatchDetailId,
						NULL,
						NULL,
						1)
								
			SET @TotalDebit = 0;
			SET @TotalCredit = 0;

			SELECT @TotalDebit = SUM([DebitAmount]),
			       @TotalCredit = SUM([CreditAmount]) 
			  FROM [dbo].[CommonBatchDetails] WITH(NOLOCK) 
			 WHERE [JournalBatchDetailId] = @JournalBatchDetailId GROUP BY [JournalBatchDetailId];

			UPDATE [dbo].[BatchDetails] 
			   SET [DebitAmount] = @TotalDebit,
			       [CreditAmount] = @TotalCredit,
				   [UpdatedDate] = GETUTCDATE(),
				   [UpdatedBy] = @UpdateBy
		     WHERE [JournalBatchDetailId] = @JournalBatchDetailId;
		  END
		END
		
		SELECT @TotalDebit = SUM([DebitAmount]),
		       @TotalCredit = SUM([CreditAmount]) 
		  FROM [dbo].[BatchDetails] WITH(NOLOCK) 
		 WHERE [JournalBatchHeaderId] = @JournalBatchHeaderId AND [IsDeleted] = 0 

		SET @TotalBalance = (@TotalDebit - @TotalCredit);

		UPDATE [dbo].[CodePrefixes] 
		   SET [CurrentNummber] = @currentNo 
		 WHERE [CodeTypeId] = @CodeTypeId 
		   AND [MasterCompanyId] = @MasterCompanyId;
		   
	    UPDATE [dbo].[BatchHeader] 
		   SET [TotalDebit] = @TotalDebit,
		       [TotalCredit] = @TotalCredit,
			   [TotalBalance] = @TotalBalance,
			   [UpdatedDate] = GETUTCDATE(),
			   [UpdatedBy] = @UpdateBy 
		 WHERE [JournalBatchHeaderId] = @JournalBatchHeaderId;

	END TRY
	BEGIN CATCH
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
		-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_PostInternalWorkOrderTearDownBatchDetails'               
			  , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@WorkOrderId, '') AS VARCHAR(100))  
              , @ApplicationName VARCHAR(100) = 'PAS'
		-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
              exec spLogException 
                       @DatabaseName           = @DatabaseName
                     , @AdhocComments          = @AdhocComments
                     , @ProcedureParameters    = @ProcedureParameters
                     , @ApplicationName        = @ApplicationName
                     , @ErrorLogID                    = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
	END CATCH
END
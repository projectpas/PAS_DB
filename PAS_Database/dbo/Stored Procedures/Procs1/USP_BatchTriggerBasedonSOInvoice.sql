/*************************************************************           
 ** File:   [USP_BatchTriggerBasedonSOInvoice]
 ** Author:  Deep Patel
 ** Description: This stored procedure is used USP_BatchTriggerBasedonSOInvoice
 ** Purpose:         
 ** Date:   08/11/2022
          
 ** PARAMETERS: @JournalBatchHeaderId bigint
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    08/11/2022  Deep Patel     Created
	2	 02/1/2024	 AMIT GHEDIYA	added isperforma Flage for SO
     
-- EXEC USP_BatchTriggerBasedonSOInvoice 3
   EXEC [dbo].[USP_BatchTriggerBasedonSOInvoice] 1,267,283,385,0,52712,1,'fff',0,90,'wo',1,'admin'
************************************************************************/
CREATE PROCEDURE [dbo].[USP_BatchTriggerBasedonSOInvoice]
@DistributionMasterId bigint=NULL,
@ReferenceId bigint=NULL,
@ReferencePartId bigint=NULL,
@ReferencePieceId bigint=NULL,
@InvoiceId bigint=NULL,
@StocklineId bigint=NULL,
@Qty int=0,
--@laborType varchar(200),
--@issued  bit,
@Amount Decimal(18,2),
@ModuleName varchar(200),
@MasterCompanyId Int,
@UpdateBy varchar(200) 
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN

	         Declare @JournalTypeId int
	         Declare @JournalTypeCode varchar(200) 
	         Declare @JournalBatchHeaderId bigint
	         Declare @GlAccountId int
	         Declare @StatusId int
	         Declare @StatusName varchar(200)
	         Declare @StartsFrom varchar(200)='00'
	         Declare @CurrentNumber int
	         Declare @GlAccountName varchar(200) 
	         Declare @GlAccountNumber varchar(200) 
	         Declare @JournalTypename varchar(200) 
	         Declare @Distributionname varchar(200) 
	         Declare @CustomerId bigint
	         Declare @ManagementStructureId bigint
	         Declare @CustomerName varchar(200)
             Declare @SalesOrderNumber varchar(200) 
             Declare @MPNName varchar(200) 
	         Declare @PiecePNId bigint
             Declare @PiecePN varchar(200) 
             Declare @ItemmasterId bigint
	         Declare @PieceItemmasterId bigint
	         Declare @CustRefNumber varchar(200)
	         declare @LineNumber int=1
	         declare @TotalDebit decimal(18,2)=0
	         declare @TotalCredit decimal(18,2)=0
	         declare @TotalBalance decimal(18,2)=0
	         --declare @Qty int =0
	         declare @UnitPrice decimal(18,2)=0
	         declare @LaborHrs decimal(18,2)=0
	         declare @DirectLaborCost decimal(18,2)=0
	         declare @OverheadCost decimal(18,2)=0
	         declare @partId bigint=0
			 declare @batch varchar(100)
			 declare @AccountingPeriod varchar(100)
			 declare @AccountingPeriodId bigint=0
			 declare @CurrentPeriodId bigint=0
			  declare @Currentbatch varchar(100)
	         declare @LastMSLevel varchar(200)
			 declare @AllMSlevels varchar(max)
			 declare @DistributionSetupId int=0
			 declare @IsAccountByPass bit=0
			 declare @DistributionCode varchar(200)
			 declare @InvoiceTotalCost decimal(18,2)=0
	         declare @MaterialCost decimal(18,2)=0
	         declare @LaborOverHeadCost decimal(18,2)=0
	         declare @FreightCost decimal(18,2)=0
			 declare @SalesTax decimal(18,2)=0
			 declare @InvoiceNo varchar(100)
			 declare @MiscChargesCost decimal(18,2)=0
			 declare @LaborCost decimal(18,2)=0
			 declare @InvoiceLaborCost decimal(18,2)=0
			 declare @RevenuWO decimal(18,2)=0
			 declare @CurrentManagementStructureId bigint=0
			 declare @JournalBatchDetailId bigint=0
			 select @IsAccountByPass =IsAccountByPass from MasterCompany WITH(NOLOCK)  where MasterCompanyId= @MasterCompanyId
	         select @DistributionCode =DistributionCode from DistributionMaster WITH(NOLOCK)  where ID= @DistributionMasterId
	         select @StatusId =Id,@StatusName=name from BatchStatus WITH(NOLOCK)  where Name= 'Open'
	         select top 1 @JournalTypeId =JournalTypeId from DistributionSetup WITH(NOLOCK)  where DistributionMasterId =@DistributionMasterId
	         select @JournalBatchHeaderId =JournalBatchHeaderId from BatchHeader WITH(NOLOCK)  where JournalTypeId= @JournalTypeId and StatusId=@StatusId
	         select @JournalTypeCode =JournalTypeCode,@JournalTypename=JournalTypeName from JournalType WITH(NOLOCK)  where ID= @JournalTypeId
	         --select @CurrentManagementStructureId =ManagementStructureId from Employee WITH(NOLOCK)  where CONCAT(FirstName,' ',LastName) IN (@UpdateBy) and MasterCompanyId=@MasterCompanyId
			 select @CurrentManagementStructureId =ManagementStructureId from Employee WITH(NOLOCK)  where CONCAT(TRIM(FirstName),'',TRIM(LastName)) IN (replace(@UpdateBy, ' ', '')) and MasterCompanyId=@MasterCompanyId
	         DECLARE @currentNo AS BIGINT = 0;
			 DECLARE @CodeTypeId AS BIGINT = 74;
			 DECLARE @JournalTypeNumber varchar(100);
			 DECLARE @CustomerTypeId INT=0;
			 DECLARE @CustomerTypeName varchar(50);
			 DECLARE @StocklineNumber varchar(50);
			 DECLARE @FreightBillingMethodId INT;
			 DECLARE @ChargesBillingMethodId INT;
			 declare @CommonJournalBatchDetailId bigint=0;
			 if((@JournalTypeCode ='SOI') and @IsAccountByPass=0)
			 BEGIN
			   
			          select @SalesOrderNumber = SalesOrderNumber,@CustomerId=CustomerId,@CustomerName= CustomerName,@CustRefNumber=CustomerReference,@ManagementStructureId =ManagementStructureId,
					   @FreightBillingMethodId = FreightBilingMethodId,@ChargesBillingMethodId=ChargesBilingMethodId from SalesOrder WITH(NOLOCK)  where SalesOrderId=@ReferenceId
					  select @CustomerTypeId = c.CustomerAffiliationId,@CustomerTypeName = caf.[Description] from dbo.Customer c WITH(NOLOCK)
							INNER JOIN dbo.CustomerAffiliation caf WITH(NOLOCK) on c.CustomerAffiliationId = caf.CustomerAffiliationId Where c.CustomerId=@CustomerId;
		              --select @partId=WorkOrderPartNoId from WorkOrderWorkFlow where WorkFlowWorkOrderId=@ReferencePartId
					  SET @partId = @ReferencePartId;
	                  select @ItemmasterId=ItemMasterId from SalesOrderPart WITH(NOLOCK)  where SalesOrderId=@ReferenceId and SalesOrderPartId=@partId
	                  select @MPNName = partnumber from ItemMaster WITH(NOLOCK)  where ItemMasterId=@ItemmasterId 
	                  select @LastMSLevel=LastMSLevel,@AllMSlevels=AllMSlevels from SalesOrderManagementStructureDetails  where ReferenceID=@ReferenceId
					  select @StocklineNumber=StockLineNumber from Stockline  where StockLineId=@StockLineId
					  select top 1  @AccountingPeriodId=acc.AccountingCalendarId,@AccountingPeriod=PeriodName from EntityStructureSetup est WITH(NOLOCK) 
					  inner join ManagementStructureLevel msl WITH(NOLOCK) on est.Level1Id = msl.ID 
					  inner join AccountingCalendar acc WITH(NOLOCK) on msl.LegalEntityId = acc.LegalEntityId and acc.IsDeleted =0
					  where est.EntityStructureId=@CurrentManagementStructureId and acc.MasterCompanyId=@MasterCompanyId  and CAST(getdate() as date)   >= CAST(FromDate as date) and  CAST(getdate() as date) <= CAST(ToDate as date)
		              Set @ReferencePartId=@partId	
					  SELECT @InvoiceNo=InvoiceNo,@SalesTax=(isnull(SalesTax,0)+ isnull(OtherTax,0) ) from SalesOrderBillingInvoicing Where SOBillingInvoicingId=@InvoiceId AND ISNULL(IsProforma,0) = 0;

	            IF OBJECT_ID(N'tempdb..#tmpCodePrefixes') IS NOT NULL
				BEGIN
				DROP TABLE #tmpCodePrefixes
				END
				
				CREATE TABLE #tmpCodePrefixes
				(
					 ID BIGINT NOT NULL IDENTITY, 
					 CodePrefixId BIGINT NULL,
					 CodeTypeId BIGINT NULL,
					 CurrentNumber BIGINT NULL,
					 CodePrefix VARCHAR(50) NULL,
					 CodeSufix VARCHAR(50) NULL,
					 StartsFrom BIGINT NULL,
				)

				INSERT INTO #tmpCodePrefixes (CodePrefixId,CodeTypeId,CurrentNumber, CodePrefix, CodeSufix, StartsFrom) 
				SELECT CodePrefixId, CP.CodeTypeId, CurrentNummber, CodePrefix, CodeSufix, StartsFrom 
				FROM dbo.CodePrefixes CP WITH(NOLOCK) JOIN dbo.CodeTypes CT ON CP.CodeTypeId = CT.CodeTypeId
				WHERE CT.CodeTypeId IN (@CodeTypeId) AND CP.MasterCompanyId = @MasterCompanyId AND CP.IsActive = 1 AND CP.IsDeleted = 0;

				  IF(EXISTS (SELECT 1 FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId))
				BEGIN 
					SELECT 
						@currentNo = CASE WHEN CurrentNumber > 0 THEN CAST(CurrentNumber AS BIGINT) + 1 
							ELSE CAST(StartsFrom AS BIGINT) + 1 END 
					FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId

					SET @JournalTypeNumber = (SELECT * FROM dbo.udfGenerateCodeNumber(@currentNo,(SELECT CodePrefix FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId), (SELECT CodeSufix FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId)))
				END
				ELSE 
				BEGIN
					ROLLBACK TRAN;
				END


				  IF NOT EXISTS(select JournalBatchHeaderId from BatchHeader WITH(NOLOCK)  where JournalTypeId= @JournalTypeId and  CAST(EntryDate AS DATE) = CAST(GETUTCDATE() AS DATE)and StatusId=@StatusId AND CustomerTypeId=@CustomerTypeId)
                  BEGIN

			              IF NOT EXISTS(select JournalBatchHeaderId from BatchHeader WITH(NOLOCK))
                           BEGIN
			                set @batch ='001'
							set @Currentbatch='001'
			               END
			               ELSE
			               BEGIN

			                  SELECT top 1 @Currentbatch = CASE WHEN CurrentNumber > 0 THEN CAST(CurrentNumber AS BIGINT) + 1 
				   							ELSE  1 END 
				   					FROM BatchHeader WITH(NOLOCK) Order by JournalBatchHeaderId desc 

							 if(CAST(@Currentbatch AS BIGINT) >99)
							 begin

							   SET @batch = CASE WHEN CAST(@Currentbatch AS BIGINT) > 99 THEN cast(@Currentbatch as varchar(100))
				   							ELSE CONCAT('00', CAST(@Currentbatch AS VARCHAR(50))) END 
							 end
							 Else if(CAST(@Currentbatch AS BIGINT) >9)
							 begin

							   SET @batch = CASE WHEN CAST(@Currentbatch AS BIGINT) > 99 THEN cast(@Currentbatch as varchar(100))
				   							ELSE CONCAT('0', CAST(@Currentbatch AS VARCHAR(50))) END 
							 end
							 else
							 begin
							    SET @batch = CASE WHEN CAST(@Currentbatch AS BIGINT) > 99 THEN cast(@Currentbatch as varchar(100))
				   							ELSE CONCAT('00', CAST(@Currentbatch AS VARCHAR(50))) END 

							 end

							
			               
						  END

			             
				          SET @CurrentNumber = CAST(@Currentbatch AS BIGINT) 
                          SET @batch = CAST(@JournalTypeCode +' '+cast(@batch as varchar(100)) as varchar(100))
				           print @CurrentNumber
				          
                           INSERT INTO [dbo].[BatchHeader]
                                      ([BatchName],[CurrentNumber],[EntryDate],[AccountingPeriod],AccountingPeriodId,[StatusId],[StatusName],[JournalTypeId],[JournalTypeName],[TotalDebit],[TotalCredit],[TotalBalance],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[Module],[CustomerTypeId])
                           VALUES
                                      (@batch,@CurrentNumber,GETUTCDATE(),@AccountingPeriod,@AccountingPeriodId,@StatusId,@StatusName,@JournalTypeId,@JournalTypename,@Amount,@Amount,0,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,'SOI',@CustomerTypeId);
            	          
				          SELECT @JournalBatchHeaderId = SCOPE_IDENTITY()
				          Update BatchHeader set CurrentNumber=@CurrentNumber  where JournalBatchHeaderId= @JournalBatchHeaderId
						   
                 END
			      ELSE
				  BEGIN
				    	SELECT @JournalBatchHeaderId=JournalBatchHeaderId,@CurrentPeriodId=isnull(AccountingPeriodId,0) from BatchHeader WITH(NOLOCK)  where JournalTypeId= @JournalTypeId and StatusId=@StatusId and CustomerTypeId=@CustomerTypeId
			            SELECT @LineNumber = CASE WHEN LineNumber > 0 THEN CAST(LineNumber AS BIGINT) + 1 ELSE  1 END 
				   					         FROM BatchDetails WITH(NOLOCK) where JournalBatchHeaderId=@JournalBatchHeaderId  Order by JournalBatchDetailId desc 
				    
					   if(@CurrentPeriodId =0)
					   begin
					      Update BatchHeader set AccountingPeriodId=@AccountingPeriodId,AccountingPeriod=@AccountingPeriod   where JournalBatchHeaderId= @JournalBatchHeaderId
					   END
				  END

                  IF(UPPER(@DistributionCode) = UPPER('SOINVOICE'))
	              BEGIN
				     
					 Declare @UnitSalesPricePerUnit decimal(18,2)=0;
					 Declare @AccountsReceivablesAmount decimal(18,2)=0;
					 Declare @UnitSalesPrice decimal(18,2)=0;
					 SELECT @UnitSalesPricePerUnit=UnitSalesPricePerUnit,@UnitSalesPrice=UnitSalePrice from dbo.SalesOrderPart WITH(NOLOCK) where SalesOrderPartId=@ReferencePartId;

					 IF(@FreightBillingMethodId = 3)
					 BEGIN
						SELECT @FreightCost = SUM(isnull(TotalFreight,0)) from dbo.SalesOrder WHERE SalesOrderId=@ReferenceId;
					 END
					 ELSE
					 BEGIN
						SELECT @FreightCost = SUM(isnull(BillingAmount,0)) from dbo.SalesOrderFreight WHERE SalesOrderId=@ReferenceId AND SalesOrderPartId=@ReferencePartId;
					 END

					 IF(@ChargesBillingMethodId = 3)
					 BEGIN
						SELECT @MiscChargesCost = SUM(isnull(TotalCharges,0)) from dbo.SalesOrder WHERE SalesOrderId=@ReferenceId;
					 END
					 ELSE
					 BEGIN
						SELECT @MiscChargesCost = SUM(isnull(BillingAmount,0)) from dbo.SalesOrderCharges WHERE SalesOrderId=@ReferenceId AND SalesOrderPartId=@ReferencePartId;
					 END

					 SET @AccountsReceivablesAmount = (@UnitSalesPricePerUnit);
					 
					 set @RevenuWO=@InvoiceTotalCost-(@FreightCost+@MiscChargesCost+@SalesTax)
					 -----Revenue - SO------
					 SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName from DistributionSetup WITH(NOLOCK)  where UPPER(Name) =UPPER('Revenue - SO') And DistributionMasterId=@DistributionMasterId
				     
					 INSERT INTO [dbo].[BatchDetails]
                            (JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
                     VALUES
                           (@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,0,0 ,@UnitSalesPricePerUnit,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0)

                     SET @JournalBatchDetailId=SCOPE_IDENTITY()

					 INSERT INTO [dbo].[CommonBatchDetails]
                            (JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
                     VALUES
                           (@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,0,0 ,@UnitSalesPricePerUnit,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0)

					 SET @CommonJournalBatchDetailId=SCOPE_IDENTITY()

					 INSERT INTO [dbo].[SalesOrderBatchDetails]
                      (JournalBatchDetailId,[JournalBatchHeaderId],[CustomerTypeId],[CustomerType],[CustomerId],[CustomerName],[ItemMasterId],[PartId],[PartNumber],[SalesOrderId] ,[SalesOrderNumber],[DocumentId],[DocumentNumber] ,[StocklineId] ,StocklineNumber,ARControlNumber,CustomerRef,CommonJournalBatchDetailId)
                     VALUES
                      (@JournalBatchDetailId,@JournalBatchHeaderId,@CustomerTypeId ,@CustomerTypeName ,@CustomerId,@CustomerName,@ItemmasterId,@partId,@MPNName ,@ReferenceId,@SalesOrderNumber ,@InvoiceId,@InvoiceNo,@StocklineId,@StocklineNumber,NULL,@CustRefNumber,@CommonJournalBatchDetailId)

					
					  -----Misc Charges------
					  SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName from DistributionSetup WITH(NOLOCK)  where UPPER(Name) =UPPER('Misc Charges') And DistributionMasterId=@DistributionMasterId

					 if(@MiscChargesCost >0)
					 begin
							IF(@ChargesBillingMethodId = 3)
							BEGIN
								IF NOT EXISTS(Select 1 FROM dbo.BatchDetails bt inner join DBO.SalesOrderBatchDetails SOBT on bt.JournalBatchDetailId = SOBT.JournalBatchDetailId
														WHERE bt.DistributionName = 'Misc Charges' AND SOBT.DocumentId=@InvoiceId)
								BEGIN
										SET @AccountsReceivablesAmount = (@UnitSalesPricePerUnit + @FreightCost + @MiscChargesCost);
										--SET @currentNo = @currentNo+1
									 --   SET @JournalTypeNumber = (SELECT * FROM dbo.udfGenerateCodeNumber(@currentNo,(SELECT CodePrefix FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId), (SELECT CodeSufix FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId)))
					 
									    --INSERT INTO [dbo].[BatchDetails]
									    --(JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
									    --VALUES
									    --(@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,2 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,0,0 ,@MiscChargesCost,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels  ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0)
									  
									    -- SET @JournalBatchDetailId=SCOPE_IDENTITY()

										INSERT INTO [dbo].[CommonBatchDetails]
										(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
										VALUES
										(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,0,0 ,@MiscChargesCost,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0)

										SET @CommonJournalBatchDetailId=SCOPE_IDENTITY()

									    INSERT INTO [dbo].[SalesOrderBatchDetails]
									     (JournalBatchDetailId,[JournalBatchHeaderId],[CustomerTypeId],[CustomerType],[CustomerId],[CustomerName],[ItemMasterId],[PartId],[PartNumber],[SalesOrderId] ,[SalesOrderNumber],[DocumentId],[DocumentNumber] ,[StocklineId] ,StocklineNumber,ARControlNumber,CustomerRef,CommonJournalBatchDetailId)
									    VALUES
									     (@JournalBatchDetailId,@JournalBatchHeaderId,@CustomerTypeId ,@CustomerTypeName ,@CustomerId,@CustomerName,@ItemmasterId,@partId,@MPNName ,@ReferenceId,@SalesOrderNumber ,@InvoiceId,@InvoiceNo,@StocklineId,@StocklineNumber,NULL,@CustRefNumber,@CommonJournalBatchDetailId)
								END
							END
							ELSE
							BEGIN
								SET @AccountsReceivablesAmount = (@UnitSalesPricePerUnit + @FreightCost + @MiscChargesCost);
								--SET @currentNo = @currentNo+1
							 --   SET @JournalTypeNumber = (SELECT * FROM dbo.udfGenerateCodeNumber(@currentNo,(SELECT CodePrefix FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId), (SELECT CodeSufix FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId)))
					 		  
							     --INSERT INTO [dbo].[BatchDetails]
							     --(JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
							     --VALUES
							     --(@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,2 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,0,0 ,@MiscChargesCost,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels  ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0)
							   
							     --SET @JournalBatchDetailId=SCOPE_IDENTITY()

								 INSERT INTO [dbo].[CommonBatchDetails]
								 (JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
								VALUES
								(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,0,0 ,@MiscChargesCost,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0)

								SET @CommonJournalBatchDetailId=SCOPE_IDENTITY()

					             INSERT INTO [dbo].[SalesOrderBatchDetails]
                                  (JournalBatchDetailId,[JournalBatchHeaderId],[CustomerTypeId],[CustomerType],[CustomerId],[CustomerName],[ItemMasterId],[PartId],[PartNumber],[SalesOrderId] ,[SalesOrderNumber],[DocumentId],[DocumentNumber] ,[StocklineId] ,StocklineNumber,ARControlNumber,CustomerRef,CommonJournalBatchDetailId)
                                 VALUES
                                  (@JournalBatchDetailId,@JournalBatchHeaderId,@CustomerTypeId ,@CustomerTypeName ,@CustomerId,@CustomerName,@ItemmasterId,@partId,@MPNName ,@ReferenceId,@SalesOrderNumber ,@InvoiceId,@InvoiceNo,@StocklineId,@StocklineNumber,NULL,@CustRefNumber,@CommonJournalBatchDetailId)
							END
					 end


					 -----Freight------
					 SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName from DistributionSetup WITH(NOLOCK)  where UPPER(Name) =UPPER('Freight') And DistributionMasterId=@DistributionMasterId

					 if(@FreightCost >0)
					 begin
						IF(@FreightBillingMethodId = 3)
							BEGIN
								IF NOT EXISTS(Select 1 FROM dbo.BatchDetails bt inner join DBO.SalesOrderBatchDetails SOBT on bt.JournalBatchDetailId = SOBT.JournalBatchDetailId
														WHERE bt.DistributionName = 'Freight' AND SOBT.DocumentId=@InvoiceId)
								BEGIN
									SET @AccountsReceivablesAmount = (@UnitSalesPricePerUnit + @FreightCost + @MiscChargesCost);
									--SET @currentNo = @currentNo+1
								 --   SET @JournalTypeNumber = (SELECT * FROM dbo.udfGenerateCodeNumber(@currentNo,(SELECT CodePrefix FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId), (SELECT CodeSufix FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId)))
					 			   
								     --INSERT INTO [dbo].[BatchDetails]
								     --(JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
								     --VALUES
								     --(@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,2 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,0,0 ,@FreightCost,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0)
								   
								     --SET @JournalBatchDetailId=SCOPE_IDENTITY()

									 INSERT INTO [dbo].[CommonBatchDetails]
									(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
									VALUES
									(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,0,0 ,@FreightCost,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0)

									SET @CommonJournalBatchDetailId=SCOPE_IDENTITY()
								   
								    INSERT INTO [dbo].[SalesOrderBatchDetails]
								     (JournalBatchDetailId,[JournalBatchHeaderId],[CustomerTypeId],[CustomerType],[CustomerId],[CustomerName],[ItemMasterId],[PartId],[PartNumber],[SalesOrderId] ,[SalesOrderNumber],[DocumentId],[DocumentNumber] ,[StocklineId] ,StocklineNumber,ARControlNumber,CustomerRef,CommonJournalBatchDetailId)
								    VALUES
								     (@JournalBatchDetailId,@JournalBatchHeaderId,@CustomerTypeId ,@CustomerTypeName ,@CustomerId,@CustomerName,@ItemmasterId,@partId,@MPNName ,@ReferenceId,@SalesOrderNumber ,@InvoiceId,@InvoiceNo,@StocklineId,@StocklineNumber,NULL,@CustRefNumber,@CommonJournalBatchDetailId)
								END
						END
						ELSE
						BEGIN
							SET @AccountsReceivablesAmount = (@UnitSalesPricePerUnit + @FreightCost + @MiscChargesCost);
							--SET @currentNo = @currentNo+1
					  --      SET @JournalTypeNumber = (SELECT * FROM dbo.udfGenerateCodeNumber(@currentNo,(SELECT CodePrefix FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId), (SELECT CodeSufix FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId)))
					 
					     --   INSERT INTO [dbo].[BatchDetails]
          --                  (JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
          --                   VALUES
          --                  (@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,2 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,0,0 ,@FreightCost,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0)
                          
						    --SET @JournalBatchDetailId=SCOPE_IDENTITY()

							INSERT INTO [dbo].[CommonBatchDetails]
							(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
							VALUES
							(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,0,0 ,@FreightCost,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0)

							SET @CommonJournalBatchDetailId=SCOPE_IDENTITY()

					        INSERT INTO [dbo].[SalesOrderBatchDetails]
                             (JournalBatchDetailId,[JournalBatchHeaderId],[CustomerTypeId],[CustomerType],[CustomerId],[CustomerName],[ItemMasterId],[PartId],[PartNumber],[SalesOrderId] ,[SalesOrderNumber],[DocumentId],[DocumentNumber] ,[StocklineId] ,StocklineNumber,ARControlNumber,CustomerRef,CommonJournalBatchDetailId)
                            VALUES
                             (@JournalBatchDetailId,@JournalBatchHeaderId,@CustomerTypeId ,@CustomerTypeName ,@CustomerId,@CustomerName,@ItemmasterId,@partId,@MPNName ,@ReferenceId,@SalesOrderNumber ,@InvoiceId,@InvoiceNo,@StocklineId,@StocklineNumber,NULL,@CustRefNumber,@CommonJournalBatchDetailId)
						END
					 end

					 -----Sales Tax------
					 SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName from DistributionSetup WITH(NOLOCK)  where UPPER(Name) =UPPER('Sales Tax Payable') And DistributionMasterId=@DistributionMasterId

					 if(@SalesTax >0)
					 begin
						       INSERT INTO [dbo].[CommonBatchDetails]
									(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
									VALUES
									(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,0,0 ,@SalesTax,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0)

									SET @CommonJournalBatchDetailId=SCOPE_IDENTITY()
								   
								    INSERT INTO [dbo].[SalesOrderBatchDetails]
								     (JournalBatchDetailId,[JournalBatchHeaderId],[CustomerTypeId],[CustomerType],[CustomerId],[CustomerName],[ItemMasterId],[PartId],[PartNumber],[SalesOrderId] ,[SalesOrderNumber],[DocumentId],[DocumentNumber] ,[StocklineId] ,StocklineNumber,ARControlNumber,CustomerRef,CommonJournalBatchDetailId)
								    VALUES
								     (@JournalBatchDetailId,@JournalBatchHeaderId,@CustomerTypeId ,@CustomerTypeName ,@CustomerId,@CustomerName,@ItemmasterId,@partId,@MPNName ,@ReferenceId,@SalesOrderNumber ,@InvoiceId,@InvoiceNo,@StocklineId,@StocklineNumber,NULL,@CustRefNumber,@CommonJournalBatchDetailId)
					 END

					   -----Accounts Receivable - Trade------
					 SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName from DistributionSetup WITH(NOLOCK)  where UPPER(Name) =UPPER('Accounts Receivables - Trade') And DistributionMasterId=@DistributionMasterId
				  --   SET @currentNo = @currentNo+1
					 --SET @JournalTypeNumber = (SELECT * FROM dbo.udfGenerateCodeNumber(@currentNo,(SELECT CodePrefix FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId), (SELECT CodeSufix FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId)))
					 
					-- INSERT INTO [dbo].[BatchDetails]
					--        (JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
					-- VALUES
					--       (@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,1,@AccountsReceivablesAmount ,0,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0)
					
					--SET @JournalBatchDetailId=SCOPE_IDENTITY()

					INSERT INTO [dbo].[CommonBatchDetails]
					(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
					VALUES
					(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,1,@AccountsReceivablesAmount ,0,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0)

					SET @CommonJournalBatchDetailId=SCOPE_IDENTITY()

					INSERT INTO [dbo].[SalesOrderBatchDetails]
                     (JournalBatchDetailId,[JournalBatchHeaderId],[CustomerTypeId],[CustomerType],[CustomerId],[CustomerName],[ItemMasterId],[PartId],[PartNumber],[SalesOrderId] ,[SalesOrderNumber],[DocumentId],[DocumentNumber] ,[StocklineId] ,StocklineNumber,ARControlNumber,CustomerRef,CommonJournalBatchDetailId)
                    VALUES
                     (@JournalBatchDetailId,@JournalBatchHeaderId,@CustomerTypeId ,@CustomerTypeName ,@CustomerId,@CustomerName,@ItemmasterId,@partId,@MPNName ,@ReferenceId,@SalesOrderNumber ,@InvoiceId,@InvoiceNo,@StocklineId,@StocklineNumber,NULL,@CustRefNumber,@CommonJournalBatchDetailId)


			   	          
			         --SET @TotalBalance =@TotalDebit-@TotalCredit
					 --SET @TotalDebit=0;
					 --SET @TotalCredit=0;
					 --SELECT @TotalDebit =SUM(DebitAmount),@TotalCredit=SUM(CreditAmount) FROM CommonBatchDetails WITH(NOLOCK) where JournalBatchDetailId=@JournalBatchDetailId group by JournalBatchDetailId
			   --      Update BatchDetails set DebitAmount=@TotalDebit,CreditAmount=@TotalCredit,UpdatedDate=GETUTCDATE(),UpdatedBy=@UpdateBy   where JournalBatchDetailId=@JournalBatchDetailId


					 ----COGS - Inventory------------
					  SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName from DistributionSetup WITH(NOLOCK)  where UPPER(Name) =UPPER('COGS - Inventory') And DistributionMasterId=@DistributionMasterId
					 -- SET @currentNo = @currentNo+1
					 -- SET @JournalTypeNumber = (SELECT * FROM dbo.udfGenerateCodeNumber(@currentNo,(SELECT CodePrefix FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId), (SELECT CodeSufix FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId)))
					 
					 --INSERT INTO [dbo].[BatchDetails]
      --                      (JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
      --                     VALUES
      --                     (@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,2 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,1,@UnitSalesPrice ,0,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0)
                     
					 --SET @JournalBatchDetailId=SCOPE_IDENTITY()

					 INSERT INTO [dbo].[CommonBatchDetails]
					(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
					VALUES
					(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,1,@UnitSalesPrice ,0,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0)

					SET @CommonJournalBatchDetailId=SCOPE_IDENTITY()

					 INSERT INTO [dbo].[SalesOrderBatchDetails]
                      (JournalBatchDetailId,[JournalBatchHeaderId],[CustomerTypeId],[CustomerType],[CustomerId],[CustomerName],[ItemMasterId],[PartId],[PartNumber],[SalesOrderId] ,[SalesOrderNumber],[DocumentId],[DocumentNumber] ,[StocklineId] ,StocklineNumber,ARControlNumber,CustomerRef,CommonJournalBatchDetailId)
                     VALUES
                      (@JournalBatchDetailId,@JournalBatchHeaderId,@CustomerTypeId ,@CustomerTypeName ,@CustomerId,@CustomerName,@ItemmasterId,@partId,@MPNName ,@ReferenceId,@SalesOrderNumber ,@InvoiceId,@InvoiceNo,@StocklineId,@StocklineNumber,NULL,@CustRefNumber,@CommonJournalBatchDetailId)


					 ----Parts Sale------------
					 SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName from DistributionSetup WITH(NOLOCK)  where UPPER(Name) =UPPER('Parts Sale') And DistributionMasterId=@DistributionMasterId
					 --SET @currentNo = @currentNo+1
					 --SET @JournalTypeNumber = (SELECT * FROM dbo.udfGenerateCodeNumber(@currentNo,(SELECT CodePrefix FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId), (SELECT CodeSufix FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId)))
					 
			   --      INSERT INTO [dbo].[BatchDetails]
      --                      (JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
      --               VALUES
      --                     (@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,2 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,0,0 ,@UnitSalesPrice,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels  ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0)
				     
					 --SET @JournalBatchDetailId=SCOPE_IDENTITY()

					 INSERT INTO [dbo].[CommonBatchDetails]
					(JournalBatchDetailId,JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
					VALUES
					(@JournalBatchDetailId,@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,0,0,@UnitSalesPrice,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0)

					SET @CommonJournalBatchDetailId=SCOPE_IDENTITY()

					INSERT INTO [dbo].[SalesOrderBatchDetails]
                     (JournalBatchDetailId,[JournalBatchHeaderId],[CustomerTypeId],[CustomerType],[CustomerId],[CustomerName],[ItemMasterId],[PartId],[PartNumber],[SalesOrderId] ,[SalesOrderNumber],[DocumentId],[DocumentNumber] ,[StocklineId] ,StocklineNumber,ARControlNumber,CustomerRef,CommonJournalBatchDetailId)
                    VALUES
                     (@JournalBatchDetailId,@JournalBatchHeaderId,@CustomerTypeId ,@CustomerTypeName ,@CustomerId,@CustomerName,@ItemmasterId,@partId,@MPNName ,@ReferenceId,@SalesOrderNumber ,@InvoiceId,@InvoiceNo,@StocklineId,@StocklineNumber,NULL,@CustRefNumber,@CommonJournalBatchDetailId)


			   	          
			        --SET @TotalBalance =@TotalDebit-@TotalCredit
					SET @TotalDebit=0;
					SET @TotalCredit=0;
					SELECT @TotalDebit =SUM(DebitAmount),@TotalCredit=SUM(CreditAmount) FROM CommonBatchDetails WITH(NOLOCK) where JournalBatchDetailId=@JournalBatchDetailId group by JournalBatchDetailId
			        Update BatchDetails set DebitAmount=@TotalDebit,CreditAmount=@TotalCredit,UpdatedDate=GETUTCDATE(),UpdatedBy=@UpdateBy   where JournalBatchDetailId=@JournalBatchDetailId

			
					          
				      SELECT @TotalDebit =SUM(DebitAmount),@TotalCredit=SUM(CreditAmount) FROM BatchDetails WITH(NOLOCK) where JournalBatchHeaderId=@JournalBatchHeaderId and IsDeleted=0 group by JournalBatchHeaderId
			   	          
			          SET @TotalBalance =@TotalDebit-@TotalCredit
				      UPDATE CodePrefixes SET CurrentNummber = @currentNo WHERE CodeTypeId = @CodeTypeId AND MasterCompanyId = @MasterCompanyId    
			          Update BatchHeader set TotalDebit=@TotalDebit,TotalCredit=@TotalCredit,TotalBalance=@TotalBalance,UpdatedDate=GETUTCDATE(),UpdatedBy=@UpdateBy   where JournalBatchHeaderId= @JournalBatchHeaderId
	               END
			 
			    IF OBJECT_ID(N'tempdb..#tmpCodePrefixes') IS NOT NULL
				BEGIN
					DROP TABLE #tmpCodePrefixes 
				END
            END

END
  COMMIT  TRANSACTION



    END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'USP_BatchTriggerBasedonSOInvoice' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@DistributionMasterId, '') + ''
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
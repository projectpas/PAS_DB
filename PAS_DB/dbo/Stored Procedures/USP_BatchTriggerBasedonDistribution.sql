/*************************************************************           
 ** File:   [USP_BatchTriggerBasedonDistribution]
 ** Author:  Subhash Saliya
 ** Description: This stored procedure is used USP_BatchTriggerBasedonDistribution
 ** Purpose:         
 ** Date:   08/10/2022      
          
 ** PARAMETERS: @JournalBatchHeaderId bigint
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    08/10/2022  Subhash Saliya     Created
     
-- EXEC USP_BatchTriggerBasedonDistribution 3
   EXEC [dbo].[USP_BatchTriggerBasedonDistribution] 1,267,283,385,0,52712,1,'fff',0,90,'wo',1,'admin'
************************************************************************/
Create   PROCEDURE [dbo].[USP_BatchTriggerBasedonDistribution]
@DistributionMasterId bigint=NULL,
@ReferenceId bigint=NULL,
@ReferencePartId bigint=NULL,
@ReferencePieceId bigint=NULL,
@InvoiceId bigint=NULL,
@StocklineId bigint=NULL,
@Qty int=0,
@laborType varchar(200),
@issued  bit,
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
             Declare @WorkOrderNumber varchar(200) 
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
	         select @CurrentManagementStructureId =ManagementStructureId from Employee WITH(NOLOCK)  where CONCAT(FirstName,' ',LastName) IN (@UpdateBy) and MasterCompanyId=@MasterCompanyId
	         DECLARE @currentNo AS BIGINT = 0;
			 DECLARE @CodeTypeId AS BIGINT = 74;
			 DECLARE @JournalTypeNumber varchar(100);
			 if((@JournalTypeCode ='WOP' or @JournalTypeCode ='WOI') and @IsAccountByPass=0)
			 BEGIN
			   
			          select @WorkOrderNumber = WorkOrderNum,@CustomerId=CustomerId,@CustomerName= CustomerName from WorkOrder WITH(NOLOCK)  where WorkOrderId=@ReferenceId
		              select @partId=WorkOrderPartNoId from WorkOrderWorkFlow where WorkFlowWorkOrderId=@ReferencePartId
	                  select @ManagementStructureId =ManagementStructureId,@ItemmasterId=ItemMasterId,@CustRefNumber=CustomerReference from WorkOrderPartNumber WITH(NOLOCK)  where WorkOrderId=@ReferenceId and ID=@partId
	                  select @MPNName = partnumber from ItemMaster WITH(NOLOCK)  where ItemMasterId=@ItemmasterId 
	                  select @LastMSLevel=LastMSLevel,@AllMSlevels=AllMSlevels from WorkOrderManagementStructureDetails  where ReferenceID=@partId
					  select top 1  @AccountingPeriodId=acc.AccountingCalendarId,@AccountingPeriod=PeriodName from EntityStructureSetup est WITH(NOLOCK) 
					  inner join ManagementStructureLevel msl WITH(NOLOCK) on est.Level1Id = msl.ID 
					  inner join AccountingCalendar acc WITH(NOLOCK) on msl.LegalEntityId = acc.LegalEntityId and acc.IsDeleted =0
					  where est.EntityStructureId=@CurrentManagementStructureId and acc.MasterCompanyId=@MasterCompanyId  and CAST(getdate() as date)   >= CAST(FromDate as date) and  CAST(getdate() as date) <= CAST(ToDate as date)
		              Set @ReferencePartId=@partId	

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


				  IF NOT EXISTS(select JournalBatchHeaderId from BatchHeader WITH(NOLOCK)  where JournalTypeId= @JournalTypeId and  CAST(EntryDate AS DATE) = CAST(GETUTCDATE() AS DATE)and StatusId=@StatusId)
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
                                      ([BatchName],[CurrentNumber],[EntryDate],[AccountingPeriod],AccountingPeriodId,[StatusId],[StatusName],[JournalTypeId],[JournalTypeName],[TotalDebit],[TotalCredit],[TotalBalance],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[Module])
                           VALUES
                                      (@batch,@CurrentNumber,GETUTCDATE(),@AccountingPeriod,@AccountingPeriodId,@StatusId,@StatusName,@JournalTypeId,@JournalTypename,@Amount,@Amount,0,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0,'WO');
            	          
				          SELECT @JournalBatchHeaderId = SCOPE_IDENTITY()
				          Update BatchHeader set CurrentNumber=@CurrentNumber  where JournalBatchHeaderId= @JournalBatchHeaderId
						   
                 END
			      ELSE
				  BEGIN
				    	SELECT @JournalBatchHeaderId=JournalBatchHeaderId,@CurrentPeriodId=isnull(AccountingPeriodId,0) from BatchHeader WITH(NOLOCK)  where JournalTypeId= @JournalTypeId and StatusId=@StatusId
			            SELECT @LineNumber = CASE WHEN LineNumber > 0 THEN CAST(LineNumber AS BIGINT) + 1 ELSE  1 END 
				   					         FROM BatchDetails WITH(NOLOCK) where JournalBatchHeaderId=@JournalBatchHeaderId  Order by JournalBatchDetailId desc 
				    
					   if(@CurrentPeriodId =0)
					   begin
					      Update BatchHeader set AccountingPeriodId=@AccountingPeriodId,AccountingPeriod=@AccountingPeriod   where JournalBatchHeaderId= @JournalBatchHeaderId
					   END
				  END

			      IF(UPPER(@DistributionCode) = UPPER('WOMATERIALGRIDTAB'))
	              BEGIN

		              SELECT @PieceItemmasterId=ItemMasterId,@UnitPrice=UnitCost,@Amount=(@Qty * UnitCost) from WorkOrderMaterialStockLine  where StockLineId=@StocklineId
		              SELECT @PiecePN = partnumber from ItemMaster WITH(NOLOCK)  where ItemMasterId=@PieceItemmasterId 
				      SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName from DistributionSetup WITH(NOLOCK)  where UPPER(Name) =UPPER('WIP - Parts')
			   		          
					          
				     IF(@issued =1)
				     BEGIN

				     INSERT INTO [dbo].[BatchDetails]
                            (JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate],[JournalTypeId],[JournalTypeName],[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
                     VALUES
                           (@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,1,@Amount ,0,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0)

                     SET @JournalBatchDetailId=SCOPE_IDENTITY()

					 INSERT INTO [dbo].[WorkOrderBatchDetails]
                            (JournalBatchDetailId,[JournalBatchHeaderId],[ReferenceId],[ReferenceName],[MPNPartId],[MPNName],[PiecePNId],[PiecePN],[CustomerId],[CustomerName] ,[InvoiceId],[InvoiceName],[ARControlNum] ,[CustRefNumber] ,Qty,UnitPrice,LaborHrs,DirectLaborCost,OverheadCost)
                     VALUES
                           (@JournalBatchDetailId,@JournalBatchHeaderId,@ReferenceId ,@WorkOrderNumber ,@ReferencePartId,@MPNName,@ReferencePieceId,@PiecePN,@CustomerId ,@CustomerName,null ,null,null,@CustRefNumber,@Qty,@UnitPrice,@LaborHrs,@DirectLaborCost,@OverheadCost)

			         SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName from DistributionSetup WITH(NOLOCK)  where UPPER(Name) =UPPER('Inventory - Parts')

					 SET @currentNo = @currentNo+1
					 SET @JournalTypeNumber = (SELECT * FROM dbo.udfGenerateCodeNumber(@currentNo,(SELECT CodePrefix FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId), (SELECT CodeSufix FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId)))
			         INSERT INTO [dbo].[BatchDetails]
                            (JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate],[JournalTypeId],[JournalTypeName],[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
                     VALUES
                           (@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,2 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,0,0 ,@Amount,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels  ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0)
				
				              SET @JournalBatchDetailId=SCOPE_IDENTITY()

					 INSERT INTO [dbo].[WorkOrderBatchDetails]
                            (JournalBatchDetailId,[JournalBatchHeaderId],[ReferenceId],[ReferenceName],[MPNPartId],[MPNName],[PiecePNId],[PiecePN],[CustomerId],[CustomerName] ,[InvoiceId],[InvoiceName],[ARControlNum] ,[CustRefNumber] ,Qty,UnitPrice,LaborHrs,DirectLaborCost,OverheadCost)
                     VALUES
                           (@JournalBatchDetailId,@JournalBatchHeaderId,@ReferenceId ,@WorkOrderNumber ,@ReferencePartId,@MPNName,@ReferencePieceId,@PiecePN,@CustomerId ,@CustomerName,null ,null,null,@CustRefNumber,@Qty,@UnitPrice,@LaborHrs,@DirectLaborCost,@OverheadCost)
				
				end
				else
				begin

				      INSERT INTO [dbo].[BatchDetails]
                            (JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate],[JournalTypeId],[JournalTypeName],[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
                      VALUES
                           (@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,0,0 ,@Amount,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0)

                     SET @JournalBatchDetailId=SCOPE_IDENTITY()

					 INSERT INTO [dbo].[WorkOrderBatchDetails]
                            (JournalBatchDetailId,[JournalBatchHeaderId],[ReferenceId],[ReferenceName],[MPNPartId],[MPNName],[PiecePNId],[PiecePN],[CustomerId],[CustomerName] ,[InvoiceId],[InvoiceName],[ARControlNum] ,[CustRefNumber] ,Qty,UnitPrice,LaborHrs,DirectLaborCost,OverheadCost)
                     VALUES
                           (@JournalBatchDetailId,@JournalBatchHeaderId,@ReferenceId ,@WorkOrderNumber ,@ReferencePartId,@MPNName,@ReferencePieceId,@PiecePN,@CustomerId ,@CustomerName,null ,null,null,@CustRefNumber,@Qty,@UnitPrice,@LaborHrs,@DirectLaborCost,@OverheadCost)

			         SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName from DistributionSetup WITH(NOLOCK)  where UPPER(Name) =UPPER('Inventory - Parts')

					 SET @currentNo = @currentNo+1
					 SET @JournalTypeNumber = (SELECT * FROM dbo.udfGenerateCodeNumber(@currentNo,(SELECT CodePrefix FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId), (SELECT CodeSufix FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId)))
			         INSERT INTO [dbo].[BatchDetails]
                            (JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate],[JournalTypeId],[JournalTypeName],[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
                     VALUES
                           (@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,2 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,1,@Amount,0,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0)
				
				     SET @JournalBatchDetailId=SCOPE_IDENTITY()

					 INSERT INTO [dbo].[WorkOrderBatchDetails]
                            (JournalBatchDetailId,[JournalBatchHeaderId],[ReferenceId],[ReferenceName],[MPNPartId],[MPNName],[PiecePNId],[PiecePN],[CustomerId],[CustomerName] ,[InvoiceId],[InvoiceName],[ARControlNum] ,[CustRefNumber] ,Qty,UnitPrice,LaborHrs,DirectLaborCost,OverheadCost)
                     VALUES
                           (@JournalBatchDetailId,@JournalBatchHeaderId,@ReferenceId ,@WorkOrderNumber ,@ReferencePartId,@MPNName,@ReferencePieceId,@PiecePN,@CustomerId ,@CustomerName,null ,null,null,@CustRefNumber,@Qty,@UnitPrice,@LaborHrs,@DirectLaborCost,@OverheadCost)

				END
					          
				     SELECT @TotalDebit =SUM(DebitAmount),@TotalCredit=SUM(CreditAmount) FROM BatchDetails WITH(NOLOCK) where JournalBatchHeaderId=@JournalBatchHeaderId and IsDeleted=0 group by JournalBatchHeaderId
			   	         
			         SET @TotalBalance =@TotalDebit-@TotalCredit
				         
			         Update BatchHeader set TotalDebit=@TotalDebit,TotalCredit=@TotalCredit,TotalBalance=@TotalBalance,UpdatedDate=GETUTCDATE(),UpdatedBy=@UpdateBy   where JournalBatchHeaderId= @JournalBatchHeaderId
	                 UPDATE CodePrefixes SET CurrentNummber = @currentNo WHERE CodeTypeId = @CodeTypeId AND MasterCompanyId = @MasterCompanyId

				  END
				  IF(UPPER(@DistributionCode) = UPPER('WOLABORTAB'))
	              BEGIN
		                       select @LaborHrs=Hours,@DirectLaborCost=TotalCost,@OverheadCost=DirectLaborOHCost from WorkOrderLabor  where WorkOrderLaborId=@ReferencePieceId
							    set @Qty=0;
							   IF(@laborType='DIRECTLABOR')
							   BEGIN
							      set @Amount=@DirectLaborCost
								  set @OverheadCost=0
							     SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName from DistributionSetup WITH(NOLOCK)  where UPPER(Name) =UPPER('WIP - Direct Labor') 
							   END
							   IF(@laborType='LABOROVERHEAD')
							   BEGIN
							      set @Amount=@OverheadCost
								  set @DirectLaborCost=0
							     SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName from DistributionSetup WITH(NOLOCK)  where UPPER(Name) =UPPER('WIP - Overhead') 
							   END

				               IF NOT EXISTS(select woB.WorkOrderBatchId from WorkOrderBatchDetails woB WITH(NOLOCK)   inner JOIN BatchDetails BD  WITH(NOLOCK)  On woB.JournalBatchDetailId=BD.JournalBatchHeaderId  where woB.JournalBatchHeaderId= @JournalBatchHeaderId and PiecePNId= @ReferencePieceId and BD.DistributionSetupId =@DistributionSetupId)
                               BEGIN
							   if(@issued =1)
				               begin

				                  INSERT INTO [dbo].[BatchDetails]
                                       (JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate],[JournalTypeId],[JournalTypeName],[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
                                 VALUES
                                       (@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,1,@Amount ,0,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0)
				                
               	                SET @JournalBatchDetailId=SCOPE_IDENTITY()

					            INSERT INTO [dbo].[WorkOrderBatchDetails]
                                 (JournalBatchDetailId,[JournalBatchHeaderId],[ReferenceId],[ReferenceName],[MPNPartId],[MPNName],[PiecePNId],[PiecePN],[CustomerId],[CustomerName] ,[InvoiceId],[InvoiceName],[ARControlNum] ,[CustRefNumber] ,Qty,UnitPrice,LaborHrs,DirectLaborCost,OverheadCost)
                                VALUES
                                (@JournalBatchDetailId,@JournalBatchHeaderId,@ReferenceId ,@WorkOrderNumber ,@ReferencePartId,@MPNName,@ReferencePieceId,@PiecePN,@CustomerId ,@CustomerName,null ,null,null,@CustRefNumber,@Qty,@UnitPrice,@LaborHrs,@DirectLaborCost,@OverheadCost)

			                     IF(@laborType='DIRECTLABOR')
							     BEGIN
							       SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName from DistributionSetup WITH(NOLOCK)  where UPPER(Name) =UPPER('Direct Labor - P&L Offset') 
							     END
							     IF(@laborType='LABOROVERHEAD')
							     BEGIN
							       SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName from DistributionSetup WITH(NOLOCK)  where UPPER(Name) =UPPER('Overhead - P&L Offset') 
							     END
				                
				                SET @currentNo = @currentNo+1
					            SET @JournalTypeNumber = (SELECT * FROM dbo.udfGenerateCodeNumber(@currentNo,(SELECT CodePrefix FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId), (SELECT CodeSufix FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId)))
			                      INSERT INTO [dbo].[BatchDetails]
                                       (JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate],[JournalTypeId],[JournalTypeName],[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
                                 VALUES
                                       (@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,2 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,0,0 ,@Amount,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels  ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0)
				                 
								 SET @JournalBatchDetailId=SCOPE_IDENTITY()

					             INSERT INTO [dbo].[WorkOrderBatchDetails]
                                  (JournalBatchDetailId,[JournalBatchHeaderId],[ReferenceId],[ReferenceName],[MPNPartId],[MPNName],[PiecePNId],[PiecePN],[CustomerId],[CustomerName] ,[InvoiceId],[InvoiceName],[ARControlNum] ,[CustRefNumber] ,Qty,UnitPrice,LaborHrs,DirectLaborCost,OverheadCost)
                                 VALUES
                                  (@JournalBatchDetailId,@JournalBatchHeaderId,@ReferenceId ,@WorkOrderNumber ,@ReferencePartId,@MPNName,@ReferencePieceId,@PiecePN,@CustomerId ,@CustomerName,null ,null,null,@CustRefNumber,@Qty,@UnitPrice,@LaborHrs,@DirectLaborCost,@OverheadCost)

							 
							 end
				               else
				               begin

				                  INSERT INTO [dbo].[BatchDetails]
                                      (JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate],[JournalTypeId],[JournalTypeName],[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
                                 VALUES
                                      (@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,0,0 ,@Amount,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0)
				                
								 SET @JournalBatchDetailId=SCOPE_IDENTITY()

					             INSERT INTO [dbo].[WorkOrderBatchDetails]
                                  (JournalBatchDetailId,[JournalBatchHeaderId],[ReferenceId],[ReferenceName],[MPNPartId],[MPNName],[PiecePNId],[PiecePN],[CustomerId],[CustomerName] ,[InvoiceId],[InvoiceName],[ARControlNum] ,[CustRefNumber] ,Qty,UnitPrice,LaborHrs,DirectLaborCost,OverheadCost)
                                 VALUES
                                  (@JournalBatchDetailId,@JournalBatchHeaderId,@ReferenceId ,@WorkOrderNumber ,@ReferencePartId,@MPNName,@ReferencePieceId,@PiecePN,@CustomerId ,@CustomerName,null ,null,null,@CustRefNumber,@Qty,@UnitPrice,@LaborHrs,@DirectLaborCost,@OverheadCost)

               	               
			                     IF(@laborType='DIRECTLABOR')
							     BEGIN
							       SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName from DistributionSetup WITH(NOLOCK)  where UPPER(Name) =UPPER('Direct Labor - P&L Offset') 
							     END
							     IF(@laborType='LABOROVERHEAD')
							     BEGIN
							       SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName from DistributionSetup WITH(NOLOCK)  where UPPER(Name) =UPPER('Overhead - P&L Offset') 
							     END
				               
				                SET @currentNo = @currentNo+1
					            SET @JournalTypeNumber = (SELECT * FROM dbo.udfGenerateCodeNumber(@currentNo,(SELECT CodePrefix FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId), (SELECT CodeSufix FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId)))
			                    INSERT INTO [dbo].[BatchDetails]
                                      (JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate],[JournalTypeId],[JournalTypeName],[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
                                VALUES
                                      (@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,2 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,1,@Amount,0,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0)
				                
								SET @JournalBatchDetailId=SCOPE_IDENTITY()

					             INSERT INTO [dbo].[WorkOrderBatchDetails]
                                  (JournalBatchDetailId,[JournalBatchHeaderId],[ReferenceId],[ReferenceName],[MPNPartId],[MPNName],[PiecePNId],[PiecePN],[CustomerId],[CustomerName] ,[InvoiceId],[InvoiceName],[ARControlNum] ,[CustRefNumber] ,Qty,UnitPrice,LaborHrs,DirectLaborCost,OverheadCost)
                                 VALUES
                                  (@JournalBatchDetailId,@JournalBatchHeaderId,@ReferenceId ,@WorkOrderNumber ,@ReferencePartId,@MPNName,@ReferencePieceId,@PiecePN,@CustomerId ,@CustomerName,null ,null,null,@CustRefNumber,@Qty,@UnitPrice,@LaborHrs,@DirectLaborCost,@OverheadCost)

							
							
							END
					          
				               
							   END
							   ELSE
							   BEGIN
							   if(@issued =0)
								 BEGIN
								      INSERT INTO [dbo].[BatchDetails]
                                      (JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate],[JournalTypeId],[JournalTypeName],[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
                                 VALUES
                                      (@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,0,0 ,@Amount,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0)
				                 
								 SET @JournalBatchDetailId=SCOPE_IDENTITY()

					             INSERT INTO [dbo].[WorkOrderBatchDetails]
                                  (JournalBatchDetailId,[JournalBatchHeaderId],[ReferenceId],[ReferenceName],[MPNPartId],[MPNName],[PiecePNId],[PiecePN],[CustomerId],[CustomerName] ,[InvoiceId],[InvoiceName],[ARControlNum] ,[CustRefNumber] ,Qty,UnitPrice,LaborHrs,DirectLaborCost,OverheadCost)
                                 VALUES
                                  (@JournalBatchDetailId,@JournalBatchHeaderId,@ReferenceId ,@WorkOrderNumber ,@ReferencePartId,@MPNName,@ReferencePieceId,@PiecePN,@CustomerId ,@CustomerName,null ,null,null,@CustRefNumber,@Qty,@UnitPrice,@LaborHrs,@DirectLaborCost,@OverheadCost)

               	               
			                     IF(@laborType='DIRECTLABOR')
							     BEGIN
							       SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName from DistributionSetup WITH(NOLOCK)  where UPPER(Name) =UPPER('Direct Labor - P&L Offset') 
							     END
							     IF(@laborType='LABOROVERHEAD')
							     BEGIN
							       SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName from DistributionSetup WITH(NOLOCK)  where UPPER(Name) =UPPER('Overhead - P&L Offset') 
							     END
				               
				                SET @currentNo = @currentNo+1
					            SET @JournalTypeNumber = (SELECT * FROM dbo.udfGenerateCodeNumber(@currentNo,(SELECT CodePrefix FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId), (SELECT CodeSufix FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId)))
					 
			                    INSERT INTO [dbo].[BatchDetails]
                                      (JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate],[JournalTypeId],[JournalTypeName],[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
                                VALUES
                                      (@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,2 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,1,@Amount,0,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0)
								
								SET @JournalBatchDetailId=SCOPE_IDENTITY()

					             INSERT INTO [dbo].[WorkOrderBatchDetails]
                                  (JournalBatchDetailId,[JournalBatchHeaderId],[ReferenceId],[ReferenceName],[MPNPartId],[MPNName],[PiecePNId],[PiecePN],[CustomerId],[CustomerName] ,[InvoiceId],[InvoiceName],[ARControlNum] ,[CustRefNumber] ,Qty,UnitPrice,LaborHrs,DirectLaborCost,OverheadCost)
                                 VALUES
                                  (@JournalBatchDetailId,@JournalBatchHeaderId,@ReferenceId ,@WorkOrderNumber ,@ReferencePartId,@MPNName,@ReferencePieceId,@PiecePN,@CustomerId ,@CustomerName,null ,null,null,@CustRefNumber,@Qty,@UnitPrice,@LaborHrs,@DirectLaborCost,@OverheadCost)

						    END

				                 
				            END

							   SELECT @TotalDebit =SUM(DebitAmount),@TotalCredit=SUM(CreditAmount) FROM BatchDetails WITH(NOLOCK) where JournalBatchHeaderId=@JournalBatchHeaderId and IsDeleted=0 group by JournalBatchHeaderId
			   	                   
			                   SET @TotalBalance =@TotalDebit-@TotalCredit
				                   
			                   Update BatchHeader set TotalDebit=@TotalDebit,TotalCredit=@TotalCredit,TotalBalance=@TotalBalance,UpdatedDate=GETUTCDATE(),UpdatedBy=@UpdateBy   where JournalBatchHeaderId= @JournalBatchHeaderId
							   UPDATE CodePrefixes SET CurrentNummber = @currentNo WHERE CodeTypeId = @CodeTypeId AND MasterCompanyId = @MasterCompanyId
	                     END
                  IF(UPPER(@DistributionCode) = UPPER('WOINVOICINGTAB'))
	              BEGIN
				       
					 select top 1 @MaterialCost=PartsCost,@LaborCost=LaborCost,@LaborOverHeadCost=OverHeadCost from   WorkOrderMPNCostDetails   where WOPartNoId=@partId  
					 select @InvoiceNo=InvoiceNo,@InvoiceTotalCost=GrandTotal,@InvoiceLaborCost=LaborOverHeadCostPlus,
					        @FreightCost=isnull(FreightCostPlus,0),@SalesTax=(isnull(SalesTax,0)+ isnull(OtherTax,0) ),@MiscChargesCost=isnull(MiscChargesCostPlus,0) from WorkOrderBillingInvoicing  where BillingInvoicingId=@InvoiceId         
				     select @Qty=NoofPieces from WorkOrderBillingInvoicingItem   where BillingInvoicingId=@InvoiceId and WorkOrderPartId=@partId
					 
					 set @RevenuWO=@InvoiceTotalCost-(@FreightCost+@MiscChargesCost+@SalesTax)
					 IF(@issued =1)
				     BEGIN

					 -----COGS - Parts------
					 SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName from DistributionSetup WITH(NOLOCK)  where UPPER(Name) =UPPER('COGS - Parts')
				     
					 INSERT INTO [dbo].[BatchDetails]
                            (JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
                     VALUES
                           (@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,1,@MaterialCost ,0,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0)

                     SET @JournalBatchDetailId=SCOPE_IDENTITY()

					             INSERT INTO [dbo].[WorkOrderBatchDetails]
                                  (JournalBatchDetailId,[JournalBatchHeaderId],[ReferenceId],[ReferenceName],[MPNPartId],[MPNName],[PiecePNId],[PiecePN],[CustomerId],[CustomerName] ,[InvoiceId],[InvoiceName],[ARControlNum] ,[CustRefNumber] ,Qty,UnitPrice,LaborHrs,DirectLaborCost,OverheadCost)
                                 VALUES
                                  (@JournalBatchDetailId,@JournalBatchHeaderId,@ReferenceId ,@WorkOrderNumber ,@ReferencePartId,@MPNName,@ReferencePieceId,@PiecePN,@CustomerId ,@CustomerName,null ,null,null,@CustRefNumber,@Qty,@UnitPrice,@LaborHrs,@DirectLaborCost,@OverheadCost)

			         SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName from DistributionSetup WITH(NOLOCK)  where UPPER(Name) =UPPER('WIP - Parts')
					  SET @currentNo = @currentNo+1
					  SET @JournalTypeNumber = (SELECT * FROM dbo.udfGenerateCodeNumber(@currentNo,(SELECT CodePrefix FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId), (SELECT CodeSufix FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId)))
					 
					 INSERT INTO [dbo].[BatchDetails]
                            (JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
                           VALUES
                           (@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,2 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,0,0 ,@MaterialCost,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0)
                     
					 SET @JournalBatchDetailId=SCOPE_IDENTITY()

					             INSERT INTO [dbo].[WorkOrderBatchDetails]
                                  (JournalBatchDetailId,[JournalBatchHeaderId],[ReferenceId],[ReferenceName],[MPNPartId],[MPNName],[PiecePNId],[PiecePN],[CustomerId],[CustomerName] ,[InvoiceId],[InvoiceName],[ARControlNum] ,[CustRefNumber] ,Qty,UnitPrice,LaborHrs,DirectLaborCost,OverheadCost)
                                 VALUES
                                  (@JournalBatchDetailId,@JournalBatchHeaderId,@ReferenceId ,@WorkOrderNumber ,@ReferencePartId,@MPNName,@ReferencePieceId,@PiecePN,@CustomerId ,@CustomerName,null ,null,null,@CustRefNumber,@Qty,@UnitPrice,@LaborHrs,@DirectLaborCost,@OverheadCost)

					 -----COGS - Direct Labor------
					 SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName from DistributionSetup WITH(NOLOCK)  where UPPER(Name) =UPPER('COGS - Direct Labor')
				     SET @currentNo = @currentNo+1
					 SET @JournalTypeNumber = (SELECT * FROM dbo.udfGenerateCodeNumber(@currentNo,(SELECT CodePrefix FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId), (SELECT CodeSufix FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId)))
					 
					 INSERT INTO [dbo].[BatchDetails]
                            (JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
                     VALUES
                           (@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,1,@LaborCost ,0,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0)
						   
					  SET @JournalBatchDetailId=SCOPE_IDENTITY()

					             INSERT INTO [dbo].[WorkOrderBatchDetails]
                                  (JournalBatchDetailId,[JournalBatchHeaderId],[ReferenceId],[ReferenceName],[MPNPartId],[MPNName],[PiecePNId],[PiecePN],[CustomerId],[CustomerName] ,[InvoiceId],[InvoiceName],[ARControlNum] ,[CustRefNumber] ,Qty,UnitPrice,LaborHrs,DirectLaborCost,OverheadCost)
                                 VALUES
                                  (@JournalBatchDetailId,@JournalBatchHeaderId,@ReferenceId ,@WorkOrderNumber ,@ReferencePartId,@MPNName,@ReferencePieceId,@PiecePN,@CustomerId ,@CustomerName,null ,null,null,@CustRefNumber,@Qty,@UnitPrice,@LaborHrs,@LaborCost,0)

               
			         SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName from DistributionSetup WITH(NOLOCK)  where UPPER(Name) =UPPER('WIP - Direct Labor')
					  SET @currentNo = @currentNo+1
					 SET @JournalTypeNumber = (SELECT * FROM dbo.udfGenerateCodeNumber(@currentNo,(SELECT CodePrefix FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId), (SELECT CodeSufix FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId)))
					 
					 INSERT INTO [dbo].[BatchDetails]
                            (JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
                            VALUES
                           (@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,2 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,0,0 ,@LaborCost,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels  ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0)

					 SET @JournalBatchDetailId=SCOPE_IDENTITY()

					             INSERT INTO [dbo].[WorkOrderBatchDetails]
                                  (JournalBatchDetailId,[JournalBatchHeaderId],[ReferenceId],[ReferenceName],[MPNPartId],[MPNName],[PiecePNId],[PiecePN],[CustomerId],[CustomerName] ,[InvoiceId],[InvoiceName],[ARControlNum] ,[CustRefNumber] ,Qty,UnitPrice,LaborHrs,DirectLaborCost,OverheadCost)
                                 VALUES
                                  (@JournalBatchDetailId,@JournalBatchHeaderId,@ReferenceId ,@WorkOrderNumber ,@ReferencePartId,@MPNName,@ReferencePieceId,@PiecePN,@CustomerId ,@CustomerName,null ,null,null,@CustRefNumber,@Qty,@UnitPrice,@LaborHrs,@LaborCost,0)

					 -----COGS - Overhead------
					 SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName from DistributionSetup WITH(NOLOCK)  where UPPER(Name) =UPPER('COGS - Overhead')
				     SET @currentNo = @currentNo+1
					 SET @JournalTypeNumber = (SELECT * FROM dbo.udfGenerateCodeNumber(@currentNo,(SELECT CodePrefix FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId), (SELECT CodeSufix FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId)))
					 
					 INSERT INTO [dbo].[BatchDetails]
                            (JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
                     VALUES
                           (@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,1,@LaborOverHeadCost ,0,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0)

                     SET @JournalBatchDetailId=SCOPE_IDENTITY()

					             INSERT INTO [dbo].[WorkOrderBatchDetails]
                                  (JournalBatchDetailId,[JournalBatchHeaderId],[ReferenceId],[ReferenceName],[MPNPartId],[MPNName],[PiecePNId],[PiecePN],[CustomerId],[CustomerName] ,[InvoiceId],[InvoiceName],[ARControlNum] ,[CustRefNumber] ,Qty,UnitPrice,LaborHrs,DirectLaborCost,OverheadCost)
                                 VALUES
                                  (@JournalBatchDetailId,@JournalBatchHeaderId,@ReferenceId ,@WorkOrderNumber ,@ReferencePartId,@MPNName,@ReferencePieceId,@PiecePN,@CustomerId ,@CustomerName,null ,null,null,@CustRefNumber,@Qty,@UnitPrice,@LaborHrs,0,@LaborOverHeadCost)

			         SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName from DistributionSetup WITH(NOLOCK)  where UPPER(Name) =UPPER('WIP - Overhead')

					 SET @currentNo = @currentNo+1
					 SET @JournalTypeNumber = (SELECT * FROM dbo.udfGenerateCodeNumber(@currentNo,(SELECT CodePrefix FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId), (SELECT CodeSufix FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId)))
					 
					 INSERT INTO [dbo].[BatchDetails]
                            (JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
                            VALUES
                           (@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,2 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,0,0 ,@LaborOverHeadCost,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels  ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0)
					
					SET @JournalBatchDetailId=SCOPE_IDENTITY()

					             INSERT INTO [dbo].[WorkOrderBatchDetails]
                                  (JournalBatchDetailId,[JournalBatchHeaderId],[ReferenceId],[ReferenceName],[MPNPartId],[MPNName],[PiecePNId],[PiecePN],[CustomerId],[CustomerName] ,[InvoiceId],[InvoiceName],[ARControlNum] ,[CustRefNumber] ,Qty,UnitPrice,LaborHrs,DirectLaborCost,OverheadCost)
                                 VALUES
                                  (@JournalBatchDetailId,@JournalBatchHeaderId,@ReferenceId ,@WorkOrderNumber ,@ReferencePartId,@MPNName,@ReferencePieceId,@PiecePN,@CustomerId ,@CustomerName,null ,null,null,@CustRefNumber,@Qty,@UnitPrice,@LaborHrs,0,@LaborOverHeadCost)

					 -----Accounts Receivable - Trade------
					 SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName from DistributionSetup WITH(NOLOCK)  where UPPER(Name) =UPPER('Accounts Receivable - Trade')
				     SET @currentNo = @currentNo+1
					 SET @JournalTypeNumber = (SELECT * FROM dbo.udfGenerateCodeNumber(@currentNo,(SELECT CodePrefix FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId), (SELECT CodeSufix FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId)))
					 
					 INSERT INTO [dbo].[BatchDetails]
                            (JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
                     VALUES
                           (@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,1 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,1,@InvoiceTotalCost ,0,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0)
					
					SET @JournalBatchDetailId=SCOPE_IDENTITY()

					             INSERT INTO [dbo].[WorkOrderBatchDetails]
                                  (JournalBatchDetailId,[JournalBatchHeaderId],[ReferenceId],[ReferenceName],[MPNPartId],[MPNName],[PiecePNId],[PiecePN],[CustomerId],[CustomerName] ,[InvoiceId],[InvoiceName],[ARControlNum] ,[CustRefNumber] ,Qty,UnitPrice,LaborHrs,DirectLaborCost,OverheadCost)
                                 VALUES
                                  (@JournalBatchDetailId,@JournalBatchHeaderId,@ReferenceId ,@WorkOrderNumber ,@ReferencePartId,@MPNName,@ReferencePieceId,@PiecePN,@CustomerId ,@CustomerName,null ,null,null,@CustRefNumber,@Qty,@UnitPrice,0,0,0)

               
			         SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName from DistributionSetup WITH(NOLOCK)  where UPPER(Name) =UPPER('Revenue - WO')
					 SET @currentNo = @currentNo+1
					 SET @JournalTypeNumber = (SELECT * FROM dbo.udfGenerateCodeNumber(@currentNo,(SELECT CodePrefix FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId), (SELECT CodeSufix FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId)))
					 
			         INSERT INTO [dbo].[BatchDetails]
                            (JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
                     VALUES
                           (@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,2 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,0,0 ,@RevenuWO,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels  ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0)
				     
					 SET @JournalBatchDetailId=SCOPE_IDENTITY()

					             INSERT INTO [dbo].[WorkOrderBatchDetails]
                                  (JournalBatchDetailId,[JournalBatchHeaderId],[ReferenceId],[ReferenceName],[MPNPartId],[MPNName],[PiecePNId],[PiecePN],[CustomerId],[CustomerName] ,[InvoiceId],[InvoiceName],[ARControlNum] ,[CustRefNumber] ,Qty,UnitPrice,LaborHrs,DirectLaborCost,OverheadCost)
                                 VALUES
                                  (@JournalBatchDetailId,@JournalBatchHeaderId,@ReferenceId ,@WorkOrderNumber ,@ReferencePartId,@MPNName,@ReferencePieceId,@PiecePN,@CustomerId ,@CustomerName,null ,null,null,@CustRefNumber,@Qty,@UnitPrice,0,0,0)

					
					  SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName from DistributionSetup WITH(NOLOCK)  where UPPER(Name) =UPPER('Revenue - Misc Charge')

					 if(@MiscChargesCost >0)
					 begin
					       SET @currentNo = @currentNo+1
					       SET @JournalTypeNumber = (SELECT * FROM dbo.udfGenerateCodeNumber(@currentNo,(SELECT CodePrefix FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId), (SELECT CodeSufix FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId)))
					 
					        INSERT INTO [dbo].[BatchDetails]
                            (JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
                           VALUES
                           (@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,2 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,0,0 ,@MiscChargesCost,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels  ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0)
					      
						  SET @JournalBatchDetailId=SCOPE_IDENTITY()

					             INSERT INTO [dbo].[WorkOrderBatchDetails]
                                  (JournalBatchDetailId,[JournalBatchHeaderId],[ReferenceId],[ReferenceName],[MPNPartId],[MPNName],[PiecePNId],[PiecePN],[CustomerId],[CustomerName] ,[InvoiceId],[InvoiceName],[ARControlNum] ,[CustRefNumber] ,Qty,UnitPrice,LaborHrs,DirectLaborCost,OverheadCost)
                                 VALUES
                                  (@JournalBatchDetailId,@JournalBatchHeaderId,@ReferenceId ,@WorkOrderNumber ,@ReferencePartId,@MPNName,@ReferencePieceId,@PiecePN,@CustomerId ,@CustomerName,null ,null,null,@CustRefNumber,@Qty,@UnitPrice,0,0,0)

					 end

					 SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName from DistributionSetup WITH(NOLOCK)  where UPPER(Name) =UPPER('Revenue - Freight')

					 if(@FreightCost >0)
					 begin
					       SET @currentNo = @currentNo+1
					       SET @JournalTypeNumber = (SELECT * FROM dbo.udfGenerateCodeNumber(@currentNo,(SELECT CodePrefix FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId), (SELECT CodeSufix FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId)))
					 
					        INSERT INTO [dbo].[BatchDetails]
                            (JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
                            VALUES
                           (@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,2 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE(),@JournalTypeId ,@JournalTypename ,0,0 ,@FreightCost,@ManagementStructureId ,@ModuleName,@LastMSLevel,@AllMSlevels,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0)
                          
						  SET @JournalBatchDetailId=SCOPE_IDENTITY()

					             INSERT INTO [dbo].[WorkOrderBatchDetails]
                                  (JournalBatchDetailId,[JournalBatchHeaderId],[ReferenceId],[ReferenceName],[MPNPartId],[MPNName],[PiecePNId],[PiecePN],[CustomerId],[CustomerName] ,[InvoiceId],[InvoiceName],[ARControlNum] ,[CustRefNumber] ,Qty,UnitPrice,LaborHrs,DirectLaborCost,OverheadCost)
                                 VALUES
                                  (@JournalBatchDetailId,@JournalBatchHeaderId,@ReferenceId ,@WorkOrderNumber ,@ReferencePartId,@MPNName,@ReferencePieceId,@PiecePN,@CustomerId ,@CustomerName,null ,null,null,@CustRefNumber,@Qty,@UnitPrice,0,0,0)

					 end

					 SELECT top 1 @DistributionSetupId=ID,@DistributionName=Name,@JournalTypeId =JournalTypeId,@GlAccountId=GlAccountId,@GlAccountNumber=GlAccountNumber,@GlAccountName=GlAccountName from DistributionSetup WITH(NOLOCK)  where UPPER(Name) =UPPER('Sales Tax Payable')

					  if(@SalesTax >0)
					  begin
					         SET @currentNo = @currentNo+1
					         SET @JournalTypeNumber = (SELECT * FROM dbo.udfGenerateCodeNumber(@currentNo,(SELECT CodePrefix FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId), (SELECT CodeSufix FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId)))
					 
					        INSERT INTO [dbo].[BatchDetails]
                                 (JournalTypeNumber,CurrentNumber,DistributionSetupId,DistributionName,[JournalBatchHeaderId],[LineNumber],[GlAccountId],[GlAccountNumber],[GlAccountName] ,[TransactionDate],[EntryDate] ,[JournalTypeId],[JournalTypeName],[IsDebit],[DebitAmount] ,[CreditAmount],[ManagementStructureId],[ModuleName],LastMSLevel,AllMSlevels,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ,[IsActive] ,[IsDeleted])
                            VALUES
                                 (@JournalTypeNumber,@currentNo,@DistributionSetupId,@DistributionName,@JournalBatchHeaderId,2 ,@GlAccountId ,@GlAccountNumber ,@GlAccountName,GETUTCDATE(),GETUTCDATE() ,@JournalTypeId ,@JournalTypename ,0,0 ,@SalesTax,@ManagementStructureId,@ModuleName,@LastMSLevel,@AllMSlevels ,@MasterCompanyId,@UpdateBy,@UpdateBy,GETUTCDATE(),GETUTCDATE(),1,0)

						    SET @JournalBatchDetailId=SCOPE_IDENTITY()

					             INSERT INTO [dbo].[WorkOrderBatchDetails]
                                  (JournalBatchDetailId,[JournalBatchHeaderId],[ReferenceId],[ReferenceName],[MPNPartId],[MPNName],[PiecePNId],[PiecePN],[CustomerId],[CustomerName] ,[InvoiceId],[InvoiceName],[ARControlNum] ,[CustRefNumber] ,Qty,UnitPrice,LaborHrs,DirectLaborCost,OverheadCost)
                                 VALUES
                                  (@JournalBatchDetailId,@JournalBatchHeaderId,@ReferenceId ,@WorkOrderNumber ,@ReferencePartId,@MPNName,@ReferencePieceId,@PiecePN,@CustomerId ,@CustomerName,null ,null,null,@CustRefNumber,@Qty,@UnitPrice,0,0,0)

					 END
                     
				     
					END
			
					          
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
            , @AdhocComments     VARCHAR(150)    = 'USP_BatchTriggerBasedonDistribution' 
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
/*************************************************************           
 ** File:   [SP_SaveSOPorformaInvoicingIsBill]           
 ** Author:  AMIT GHEDIYA
 ** Description: This stored procedure is used to update isbilling flag after standard proforma invoice flag to isbiiling.
 ** Purpose:         
 ** Date:  15/02/2024   
          
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    15/02/2024   AMIT GHEDIYA		 Created
	2    04/03/2024   AMIT GHEDIYA		 Update only for Proforma records.
 	3    11/Jun/2025  RAJESH GAMI		 Modified : As new Common Billing Invoicing Table SalesOrderBillingInvoicing to BillingInvoicing
************************************************************************/

CREATE     PROCEDURE [dbo].[SP_SaveSOPorformaInvoicingIsBill]
@sobillingInvoicingId bigint NULL= 0
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;	
	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN 
		DECLARE @SOModuleId INT
		SELECT @SOModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'SalesOrder';
		IF(@sobillingInvoicingId > 0)
		BEGIN

			DECLARE @sobillngId BIGINT,
					@isProforma BIT,
					@soPartID BIGINT,
					@SalesOrderPartId BIGINT,
					@SOBillingInvoicingIds BIGINT,
					@PSOBillingInvoicingIds BIGINT,
					@COUNT AS INT = 0,
					@PCOUNT AS INT = 0,
					@SalesOrderId BIGINT = 0,
					@DepositAmt DECIMAL(18,2) = 0,
					@OldUsedDepositAmount DECIMAL(18,2) = 0,
					@TotalSalesOrderCostPlus DECIMAL(18,2) = 0,
					@UsedDepositAmt DECIMAL(18,2) = 0,
					@SOProFormaBillingInvoicingId BIGINT = 0,
					@SOisProforma BIT,
					@SalesOrderPartNoId BIGINT = 0,
					@SOProfomaBillingInvoicingId BIGINT = 0,
					@BillSOBillingInvoicingId BIGINT = 0,
					@proamount DECIMAL(18,2) = 0,
					@Depositamountpro DECIMAL(18,2) = 0,
					@RemainingAmount DECIMAL(18,2) = 0,
					@DepositRemaining DECIMAL(18,2) = 0;

		------------- Update Remaining Deposit -------------------------------------
			
			SELECT @SalesOrderId = [ReferenceId], @TotalSalesOrderCostPlus = [GrandTotal], @SOisProforma = IsPerformaInvoice
			FROM [dbo].[BillingInvoicing] WITH(NOLOCK) WHERE [BillingInvoicingId] = @sobillingInvoicingId;

			IF(@SOisProforma != 1)
			BEGIN
				--Get deposit from invoiced.
				SELECT @DepositAmt = ISNULL(SUM(ISNULL([DepositAmount], 0)),0), @OldUsedDepositAmount = ISNULL(SUM(ISNULL(UsedDeposit, 0)),0) FROM [dbo].[BillingInvoicing] WITH(NOLOCK) 
				WHERE [ReferenceId] = @SalesOrderId AND IsPerformaInvoice = 1 AND UPPER(InvoiceStatus) = 'INVOICED';

				SET @UsedDepositAmt = CASE WHEN ISNULL(@TotalSalesOrderCostPlus ,0) > ISNULL(@DepositAmt,0) THEN (ISNULL(@DepositAmt,0) - ISNULL(@OldUsedDepositAmount,0)) ELSE ISNULL(@TotalSalesOrderCostPlus ,0) END

				SELECT TOP 1 @SOProFormaBillingInvoicingId = BillingInvoicingId FROM [dbo].[BillingInvoicing] WITH(NOLOCK) 
				WHERE [ReferenceId] = @SalesOrderId AND IsPerformaInvoice = 1 AND UPPER(InvoiceStatus) = 'INVOICED';

				--Update Remaining balace
				IF(@DepositAmt > 0)
				BEGIN 
					SELECT @DepositAmt = SUM(ISNULL([DepositAmount], 0)), @OldUsedDepositAmount = SUM(ISNULL(UsedDeposit, 0)) FROM [dbo].[BillingInvoicing] WITH(NOLOCK) 
					WHERE ReferenceId = @SalesOrderId AND IsPerformaInvoice = 1 AND UPPER(InvoiceStatus) = 'INVOICED';

					SELECT @RemainingAmount = ISNULL(RemainingAmount,0) FROM [dbo].[BillingInvoicing] WITH(NOLOCK) WHERE [BillingInvoicingId] = @sobillingInvoicingId;
					
					IF(@RemainingAmount >= @UsedDepositAmt)
					BEGIN 
						IF((@DepositAmt - @OldUsedDepositAmount) > @RemainingAmount)
						BEGIN
							UPDATE [dbo].[BillingInvoicing] SET RemainingAmount = 0  WHERE [BillingInvoicingId] = @sobillingInvoicingId;
						END
						ELSE
						BEGIN
							UPDATE [dbo].[BillingInvoicing] SET RemainingAmount = ABS(ISNULL(RemainingAmount ,0) - ABS((@DepositAmt - @OldUsedDepositAmount)))  WHERE [BillingInvoicingId] = @sobillingInvoicingId;
						END
					END
					ELSE
					BEGIN 
						UPDATE [dbo].[BillingInvoicing] SET RemainingAmount = 0  WHERE [BillingInvoicingId] = @sobillingInvoicingId;
					END
				END
				
				--Update current billing add deposit amount in ProformaDeposit field
				UPDATE [dbo].[BillingInvoicing] SET ProformaDeposit = @UsedDepositAmt  WHERE [BillingInvoicingId] = @sobillingInvoicingId; 

				--SELECT @proamount = ISNULL(RemainingAmount,0), @Depositamountpro = ISNULL(ProformaDeposit,0) FROM [dbo].[BillingInvoicing] WITH(NOLOCK) WHERE [BillingInvoicingId] = @sobillingInvoicingId; 
				--IF(@proamount >= @Depositamountpro)
				--BEGIN
				--	SELECT @DepositAmt = ISNULL(SUM(ISNULL([DepositAmount], 0)),0) FROM [dbo].[BillingInvoicing] WITH(NOLOCK) 
				--	WHERE [SalesOrderId] = @SalesOrderId AND IsPerformaInvoice = 1 AND UPPER(InvoiceStatus) = 'INVOICED';
				--	IF(@DepositAmt > 0)
				--	BEGIN
				--		UPDATE [dbo].[BillingInvoicing] SET RemainingAmount = 0  WHERE [BillingInvoicingId] = @sobillingInvoicingId;
				--	END
				--END

				IF(ISNULL(@SOProFormaBillingInvoicingId, 0) > 0)
				BEGIN 
					UPDATE [dbo].[BillingInvoicing]
					SET [UsedDeposit] = ISNULL(UsedDeposit, 0) + @UsedDepositAmt
					WHERE [BillingInvoicingId] = @SOProFormaBillingInvoicingId
				END
			END

		-------------End Update Remaining Deposit -------------------------------------


			--Create Temp Table 
			IF OBJECT_ID(N'tempdb..#SalesOrderBillingInvoiceList') IS NOT NULL
			BEGIN
				DROP TABLE #SalesOrderBillingInvoiceList
			END

			CREATE TABLE #SalesOrderBillingInvoiceList(
				ID BIGINT NOT NULL IDENTITY (1, 1),
				SalesOrderPartId [BIGINT]  NULL,
				BillingInvoicingId [BIGINT]  NULL
			);

			--Create Temp Table 
			IF OBJECT_ID(N'tempdb..#PSalesOrderBillingInvoiceList') IS NOT NULL
			BEGIN
				DROP TABLE #PSalesOrderBillingInvoiceList
			END

			CREATE TABLE #PSalesOrderBillingInvoiceList(
				ID BIGINT NOT NULL IDENTITY (1, 1),
				BillingInvoicingId [BIGINT]  NULL
			);

			SELECT TOP 1 @SalesOrderPartNoId = SubReferenceId FROM [dbo].[BillingInvoicingItems] WITH(NOLOCK) WHERE [BillingInvoicingId] = @sobillingInvoicingId;
			SELECT TOP 1 @SOProfomaBillingInvoicingId = BillingInvoicingId FROM [dbo].[BillingInvoicingItems] WITH(NOLOCK) WHERE SubReferenceId = @SalesOrderPartNoId AND ISNULL(IsPerformaInvoice, 0) = 1 AND ISNULL(IsVersionIncrease, 0) = 0 AND ModuleId = @SOModuleId;

			SELECT @sobillngId = BillingInvoicingId , @soPartID = SubReferenceId , @isProforma = IsPerformaInvoice FROM DBO.BillingInvoicingItems WITH(NOLOCK) WHERE BillingInvoicingId = @sobillingInvoicingId;
			IF(ISNULL(@sobillngId,0) > 0 AND @isProforma = 0)
			BEGIN
				IF(ISNULL(@soPartID,0) > 0)
				BEGIN 
					INSERT INTO #SalesOrderBillingInvoiceList(SalesOrderPartId,BillingInvoicingId)
					(SELECT SubReferenceId,BillingInvoicingId 
					FROM BillingInvoicingItems WHERE BillingInvoicingId = @sobillingInvoicingId)--SalesOrderPartId = @soPartID AND IsPerformaInvoice = 1)

					SELECT @COUNT = MAX(ID) FROM #SalesOrderBillingInvoiceList 

					WHILE(@COUNT > 0)
					BEGIN 
						SELECT @SalesOrderPartId = SalesOrderPartId, @SOBillingInvoicingIds = BillingInvoicingId, @SalesOrderPartId = SalesOrderPartId 
						FROM #SalesOrderBillingInvoiceList WITH(NOLOCK) WHERE ID = @COUNT;
						
						--Update isbiiling after standdard invoiced post
						--UPDATE DBO.BillingInvoicingItems SET IsBilling = 1 WHERE SubReferenceId = @SalesOrderPartId AND IsPerformaInvoice = 1 AND ModuleId = @SOModuleId;

						--SELECT @BillSOBillingInvoicingId = BillingInvoicingId FROM DBO.BillingInvoicingItems  WITH(NOLOCK) WHERE SalesOrderPartId = @SalesOrderPartId AND IsPerformaInvoice = 1; 
						INSERT INTO #PSalesOrderBillingInvoiceList(BillingInvoicingId)
						(SELECT BillingInvoicingId FROM DBO.BillingInvoicingItems  WITH(NOLOCK) WHERE SubReferenceId = @SalesOrderPartId AND IsPerformaInvoice = 1  AND ModuleId = @SOModuleId)
						
						SELECT @PCOUNT = MAX(ID) FROM #PSalesOrderBillingInvoiceList

						WHILE(@PCOUNT > 0)
						BEGIN
							SELECT @PSOBillingInvoicingIds = BillingInvoicingId
							FROM #PSalesOrderBillingInvoiceList WITH(NOLOCK) WHERE ID = @PCOUNT;

							UPDATE DBO.BillingInvoicing SET IsInvoicePosted = 1, PostedDate = GETUTCDATE() WHERE BillingInvoicingId = @PSOBillingInvoicingIds AND IsPerformaInvoice = 1;

							SET @PCOUNT = @PCOUNT - 1
						END

						SET @COUNT = @COUNT - 1
					END
					
				END
			END

			--IF(ISNULL(@SOProfomaBillingInvoicingId, 0) > 0 AND @isProforma = 0)
			--BEGIN
			--	UPDATE SOBN
			--	SET SOBN.IsBilling = 1
			--	FROM [dbo].[BillingInvoicing] SOBN WITH(NOLOCK)
			--	WHERE SOBN.[BillingInvoicingId] = @SOProfomaBillingInvoicingId AND SOBN.IsPerformaInvoice = 1

			--	UPDATE SOBIN
			--	SET SOBIN.IsBilling = 1
			--	FROM [dbo].[BillingInvoicingItems] SOBIN WITH(NOLOCK)
			--	WHERE SOBIN.[BillingInvoicingId] = @SOProfomaBillingInvoicingId AND SOBIN.IsPerformaInvoice = 1  AND ModuleId = @SOModuleId
			--END

			--handle if all deposit used then all proforma need to bill
			--SELECT @DepositAmt = ISNULL(SUM(ISNULL([DepositAmount], 0)),0), @OldUsedDepositAmount = ISNULL(SUM(ISNULL(UsedDeposit, 0)),0) FROM [dbo].[BillingInvoicing] WITH(NOLOCK) 
			--WHERE [SalesOrderId] = @SalesOrderId AND IsPerformaInvoice = 1 AND UPPER(InvoiceStatus) = 'INVOICED';

			--IF(@DepositAmt = @OldUsedDepositAmount AND @isProforma = 0)
			--BEGIN
			--	UPDATE [dbo].[BillingInvoicing] SET IsBilling = 1 WHERE UPPER(InvoiceStatus) = 'INVOICED' AND IsVersionIncrease = 0 AND IsPerformaInvoice = 1 AND SalesOrderId = @SalesOrderId AND ISNULL(GrandTotal,0) > ISNULL(RemainingAmount,0);

			--	UPDATE [dbo].[BillingInvoicingItems] SET IsBilling = 1 
			--		WHERE BillingInvoicingId IN(SELECT BillingInvoicingId FROM [dbo].[BillingInvoicing] 
			--	WHERE UPPER(InvoiceStatus) = 'INVOICED' AND IsVersionIncrease = 0 AND IsPerformaInvoice = 1 AND SalesOrderId = @SalesOrderId AND ISNULL(GrandTotal,0) > ISNULL(RemainingAmount,0))
			--END
		END
	END	
	COMMIT  TRANSACTION
	END TRY 
	BEGIN CATCH      
		IF @@trancount > 0
		PRINT 'ROLLBACK'
				ROLLBACK TRANSACTION;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'SP_SaveSOPorformaInvoicingIsBill' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ CAST(ISNULL(@sobillingInvoicingId, '') AS varchar(100))
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------------------------------------
              exec spLogException 
                       @DatabaseName           = @DatabaseName
                     , @AdhocComments          = @AdhocComments
                     , @ProcedureParameters	   = @ProcedureParameters
                     , @ApplicationName        =  @ApplicationName
                     , @ErrorLogID                    = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
	END CATCH
END
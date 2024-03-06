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
			
			SELECT @SalesOrderId = [SalesOrderId], @TotalSalesOrderCostPlus = [GrandTotal], @SOisProforma = [IsProforma]
			FROM [dbo].[SalesOrderBillingInvoicing] WITH(NOLOCK) WHERE [SOBillingInvoicingId] = @sobillingInvoicingId;

			IF(@SOisProforma != 1)
			BEGIN
				--Get deposit from invoiced.
				SELECT @DepositAmt = ISNULL(SUM(ISNULL([DepositAmount], 0)),0), @OldUsedDepositAmount = ISNULL(SUM(ISNULL(UsedDeposit, 0)),0) FROM [dbo].[SalesOrderBillingInvoicing] WITH(NOLOCK) 
				WHERE [SalesOrderId] = @SalesOrderId AND IsProforma = 1 AND UPPER(InvoiceStatus) = 'INVOICED';

				SET @UsedDepositAmt = CASE WHEN ISNULL(@TotalSalesOrderCostPlus ,0) > ISNULL(@DepositAmt,0) THEN (ISNULL(@DepositAmt,0) - ISNULL(@OldUsedDepositAmount,0)) ELSE ISNULL(@TotalSalesOrderCostPlus ,0) END

				SELECT TOP 1 @SOProFormaBillingInvoicingId = SOBillingInvoicingId FROM [dbo].[SalesOrderBillingInvoicing] WITH(NOLOCK) 
				WHERE [SalesOrderId] = @SalesOrderId AND IsProforma = 1 AND UPPER(InvoiceStatus) = 'INVOICED';

				--Update Remaining balace
				IF(@DepositAmt > 0)
				BEGIN 
					SELECT @DepositAmt = SUM(ISNULL([DepositAmount], 0)), @OldUsedDepositAmount = SUM(ISNULL(UsedDeposit, 0)) FROM [dbo].[SalesOrderBillingInvoicing] WITH(NOLOCK) 
					WHERE [SalesOrderId] = @SalesOrderId AND IsProforma = 1 AND UPPER(InvoiceStatus) = 'INVOICED';

					SELECT @RemainingAmount = ISNULL(RemainingAmount,0) FROM [dbo].[SalesOrderBillingInvoicing] WITH(NOLOCK) WHERE [SOBillingInvoicingId] = @sobillingInvoicingId;
					
					IF(@RemainingAmount >= @UsedDepositAmt)
					BEGIN 
						IF((@DepositAmt - @OldUsedDepositAmount) > @RemainingAmount)
						BEGIN
							UPDATE [dbo].[SalesOrderBillingInvoicing] SET RemainingAmount = 0  WHERE [SOBillingInvoicingId] = @sobillingInvoicingId;
						END
						ELSE
						BEGIN
							UPDATE [dbo].[SalesOrderBillingInvoicing] SET RemainingAmount = ABS(ISNULL(RemainingAmount ,0) - ABS((@DepositAmt - @OldUsedDepositAmount)))  WHERE [SOBillingInvoicingId] = @sobillingInvoicingId;
						END
					END
					ELSE
					BEGIN 
						UPDATE [dbo].[SalesOrderBillingInvoicing] SET RemainingAmount = 0  WHERE [SOBillingInvoicingId] = @sobillingInvoicingId;
					END
				END
				
				--Update current billing add deposit amount in ProformaDeposit field
				UPDATE [dbo].[SalesOrderBillingInvoicing] SET ProformaDeposit = @UsedDepositAmt  WHERE [SOBillingInvoicingId] = @sobillingInvoicingId; 

				SELECT @proamount = ISNULL(RemainingAmount,0), @Depositamountpro = ISNULL(ProformaDeposit,0) FROM [dbo].[SalesOrderBillingInvoicing] WITH(NOLOCK) WHERE [SOBillingInvoicingId] = @sobillingInvoicingId; 
				IF(@proamount >= @Depositamountpro)
				BEGIN
					SELECT @DepositAmt = ISNULL(SUM(ISNULL([DepositAmount], 0)),0) FROM [dbo].[SalesOrderBillingInvoicing] WITH(NOLOCK) 
					WHERE [SalesOrderId] = @SalesOrderId AND IsProforma = 1 AND UPPER(InvoiceStatus) = 'INVOICED';
					IF(@DepositAmt > 0)
					BEGIN
						UPDATE [dbo].[SalesOrderBillingInvoicing] SET RemainingAmount = 0  WHERE [SOBillingInvoicingId] = @sobillingInvoicingId;
					END
				END

				IF(ISNULL(@SOProFormaBillingInvoicingId, 0) > 0)
				BEGIN 
					UPDATE [dbo].[SalesOrderBillingInvoicing]
					SET [UsedDeposit] = ISNULL(UsedDeposit, 0) + @UsedDepositAmt
					WHERE [SOBillingInvoicingId] = @SOProFormaBillingInvoicingId
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
				SOBillingInvoicingId [BIGINT]  NULL
			);

			--Create Temp Table 
			IF OBJECT_ID(N'tempdb..#PSalesOrderBillingInvoiceList') IS NOT NULL
			BEGIN
				DROP TABLE #PSalesOrderBillingInvoiceList
			END

			CREATE TABLE #PSalesOrderBillingInvoiceList(
				ID BIGINT NOT NULL IDENTITY (1, 1),
				SOBillingInvoicingId [BIGINT]  NULL
			);

			SELECT TOP 1 @SalesOrderPartNoId = SalesOrderPartId FROM [dbo].[SalesOrderBillingInvoicingItem] WITH(NOLOCK) WHERE [SOBillingInvoicingId] = @sobillingInvoicingId;
			SELECT TOP 1 @SOProfomaBillingInvoicingId = SOBillingInvoicingId FROM [dbo].[SalesOrderBillingInvoicingItem] WITH(NOLOCK) WHERE SalesOrderPartId = @SalesOrderPartNoId AND ISNULL(IsProforma, 0) = 1 AND ISNULL(IsVersionIncrease, 0) = 0;

			SELECT @sobillngId = SOBillingInvoicingId , @soPartID = SalesOrderPartId , @isProforma = IsProforma FROM DBO.SalesOrderBillingInvoicingItem WITH(NOLOCK) WHERE SOBillingInvoicingId = @sobillingInvoicingId;
			IF(ISNULL(@sobillngId,0) > 0 AND @isProforma = 0)
			BEGIN
				IF(ISNULL(@soPartID,0) > 0)
				BEGIN 
					INSERT INTO #SalesOrderBillingInvoiceList(SalesOrderPartId,SOBillingInvoicingId)
					(SELECT SalesOrderPartId,SOBillingInvoicingId 
					FROM SalesOrderBillingInvoicingItem WHERE SOBillingInvoicingId = @sobillingInvoicingId)--SalesOrderPartId = @soPartID AND IsProforma = 1)

					SELECT @COUNT = MAX(ID) FROM #SalesOrderBillingInvoiceList 

					WHILE(@COUNT > 0)
					BEGIN 
						SELECT @SalesOrderPartId = SalesOrderPartId, @SOBillingInvoicingIds = SOBillingInvoicingId, @SalesOrderPartId = SalesOrderPartId 
						FROM #SalesOrderBillingInvoiceList WITH(NOLOCK) WHERE ID = @COUNT;
						
						--Update isbiiling after standdard invoiced post
						UPDATE DBO.SalesOrderBillingInvoicingItem SET IsBilling = 1 WHERE SalesOrderPartId = @SalesOrderPartId AND IsProforma = 1;

						--SELECT @BillSOBillingInvoicingId = SOBillingInvoicingId FROM DBO.SalesOrderBillingInvoicingItem  WITH(NOLOCK) WHERE SalesOrderPartId = @SalesOrderPartId AND IsProforma = 1; 
						INSERT INTO #PSalesOrderBillingInvoiceList(SOBillingInvoicingId)
						(SELECT SOBillingInvoicingId FROM DBO.SalesOrderBillingInvoicingItem  WITH(NOLOCK) WHERE SalesOrderPartId = @SalesOrderPartId AND IsProforma = 1)
						
						SELECT @PCOUNT = MAX(ID) FROM #PSalesOrderBillingInvoiceList

						WHILE(@PCOUNT > 0)
						BEGIN
							SELECT @PSOBillingInvoicingIds = SOBillingInvoicingId
							FROM #PSalesOrderBillingInvoiceList WITH(NOLOCK) WHERE ID = @PCOUNT;

							UPDATE DBO.SalesOrderBillingInvoicing SET IsBilling = 1 WHERE SOBillingInvoicingId = @PSOBillingInvoicingIds AND IsProforma = 1;

							SET @PCOUNT = @PCOUNT - 1
						END

						SET @COUNT = @COUNT - 1
					END
					
				END
			END

			IF(ISNULL(@SOProfomaBillingInvoicingId, 0) > 0 AND @isProforma = 0)
			BEGIN
				UPDATE SOBN
				SET SOBN.IsBilling = 1
				FROM [dbo].[SalesOrderBillingInvoicing] SOBN WITH(NOLOCK)
				WHERE SOBN.[SOBillingInvoicingId] = @SOProfomaBillingInvoicingId AND SOBN.IsProforma = 1

				UPDATE SOBIN
				SET SOBIN.IsBilling = 1
				FROM [dbo].[SalesOrderBillingInvoicingItem] SOBIN WITH(NOLOCK)
				WHERE SOBIN.[SOBillingInvoicingId] = @SOProfomaBillingInvoicingId AND SOBIN.IsProforma = 1
			END

			--handle if all deposit used then all proforma need to bill
			SELECT @DepositAmt = ISNULL(SUM(ISNULL([DepositAmount], 0)),0), @OldUsedDepositAmount = ISNULL(SUM(ISNULL(UsedDeposit, 0)),0) FROM [dbo].[SalesOrderBillingInvoicing] WITH(NOLOCK) 
			WHERE [SalesOrderId] = @SalesOrderId AND IsProforma = 1 AND UPPER(InvoiceStatus) = 'INVOICED';

			IF(@DepositAmt = @OldUsedDepositAmount AND @isProforma = 0)
			BEGIN
				UPDATE [dbo].[SalesOrderBillingInvoicing] SET IsBilling = 1 WHERE UPPER(InvoiceStatus) = 'INVOICED' AND IsVersionIncrease = 0 AND IsProforma = 1 AND SalesOrderId = @SalesOrderId;

				UPDATE [dbo].[SalesOrderBillingInvoicingItem] SET IsBilling = 1 WHERE IsVersionIncrease = 0 AND IsProforma = 1;
			END
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
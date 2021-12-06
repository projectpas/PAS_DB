
/*************************************************************           
 ** File:   [USP_Reserve_ReleaseSubWorkOrderStockline]           
 ** Author:   Hemant Saliya
 ** Description: This stored procedure is used to Reserve Or Release Stockline for Sub WO   
 ** Purpose:         
 ** Date:   08/12/2021        
          
 ** PARAMETERS:           
 @WorkOrderId BIGINT   
 @WFWOId BIGINT  
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    08/12/2021   Hemant Saliya Created
     
 EXECUTE USP_Reserve_ReleaseSubWorkOrderStockline 409,73, 624,60,145,1,0,1

**************************************************************/ 
    
CREATE PROCEDURE [dbo].[USP_Reserve_ReleaseSubWorkOrderStockline]    
(    
@WorkOrderId  BIGINT  = NULL,
@SubWorkOrderId  BIGINT  = NULL,
@WorkOrderMaterialsId  BIGINT  = NULL,
@StocklineId  BIGINT  = NULL,
@SubWorkOrderPartNoId  BIGINT  = NULL,
@Quantity INT = NULL,
@IsCreate BIT = 0,
@UpdatedById BIGINT = NULL
)    
AS    
BEGIN    

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON    

	BEGIN TRY
		BEGIN TRANSACTION
			BEGIN

				DECLARE @SubWorkOrderStatusId BIGINT;
				DECLARE @ProvisionId BIGINT;
				DECLARE @MasterCompanyId BIGINT;
				DECLARE @PartStatusId INT;
				DECLARE @UpdatedBy VARCHAR(200);
				DECLARE @SubWOPartQty INT;
				DECLARE @ItemMasterId BIGINT;
				DECLARE @ConditionId BIGINT;
				DECLARE @SubWOQty INT;
				DECLARE @CurrentNo BIGINT;
				DECLARE @PickTicketNumber VARCHAR(100);
				DECLARE @CodeTypeId INT;
				DECLARE @WorkOrderTypeId INT;

				SELECT @UpdatedBy = FirstName + ' ' + LastName FROM dbo.Employee Where EmployeeId = @UpdatedById
				SET @PartStatusId = 3; -- WHEN RESERVE & ISSUE ID = 3
				SET @SubWOPartQty = 1; -- It's Always Single QTY
				SET @CodeTypeId = 44; -- For Pick Ticket
				SET @WorkOrderTypeId = 1 -- Customer WO Only

				IF OBJECT_ID(N'tempdb..#tmpResStockLine') IS NOT NULL
				BEGIN
				DROP TABLE #tmpResStockLine
				END
				
				IF OBJECT_ID(N'tempdb..#tmpPickTicket') IS NOT NULL
				BEGIN
				DROP TABLE #tmpPickTicket
				END

				IF OBJECT_ID(N'tempdb..#PickTicketGet') IS NOT NULL
				BEGIN
				DROP TABLE #PickTicketGet
				END

				IF OBJECT_ID(N'tempdb..#CodePrifix') IS NOT NULL
				BEGIN
				DROP TABLE #CodePrifix
				END
				
				CREATE TABLE #tmpResStockLine
				(
					 ID BIGINT NOT NULL IDENTITY, 
					 WorkOrderMaterialsId BIGINT NULL,
					 WOMStockLineId BIGINT NULL,
					 StockLineId BIGINT NULL,
					 QuantityIssued INT NULL,
					 QuantityReserved INT NULL,
					 UnitCost DECIMAL(18,2) NULL,
					 ExtendedCost DECIMAL(18,2) NULL,
					 ReservedById BIGINT NULL,
					 IssuedById BIGINT NULL,
					 IssuedDate DATETIME2(7) NULL,
					 UpdatedDate DATETIME2(7) NULL,
					 PartStatusId INT NULL,
					 ParentWorkOrderMaterialsId BIGINT NULL,
				)

				CREATE TABLE #PickTicketGet
				(
					 ID BIGINT NOT NULL IDENTITY, 
					 PartNumber VARCHAR(500) NULL,
					 StocklineId BIGINT NULL,
					 PartId BIGINT NULL,
					 ItemMasterId BIGINT NULL,
					 [Description] VARCHAR(MAX) NULL,
					 ItemGroup VARCHAR(100) NULL,
					 Manufacturer VARCHAR(100) NULL,
					 ManufacturerId  BIGINT NULL,
					 ConditionId BIGINT NULL,
					 AlternetFor VARCHAR(100) NULL,
					 StockType VARCHAR(100) NULL,
					 StockLineNumber VARCHAR(100) NULL,
					 SerialNumber VARCHAR(100) NULL,
					 ControlNumber VARCHAR(100) NULL,
					 IdNumber VARCHAR(100) NULL,
					 QtyToPick INT NULL,
					 QtyToReserve INT NULL,
					 QtyAvailable INT NULL,
					 QtyOnHand INT NULL,
					 UnitCost DECIMAL(18,2) NULL,
					 TracableToName VARCHAR(100) NULL,
					 TagType VARCHAR(500) NULL,
					 TagDate DATETIME2(7) NULL,
					 CertifiedBy VARCHAR(500 ) NULL,
					 CertifiedDate DATETIME2(7) NULL,
					 Memo VARCHAR(MAX) NULL,
					 Method VARCHAR(200) NULL,
					 MethodType VARCHAR(100) NULL,
					 PMA BIT NULL,
					 StkLineManufacturer VARCHAR(200) NULL,
				)

				CREATE TABLE #tmpPickTicket
				(
					 ID BIGINT NOT NULL IDENTITY, 
					 WOPickTicketId BIGINT NULL,
					 WOPickTicketNumber VARCHAR(50) NULL,
					 WorkOrderId BIGINT NULL,
					 CreatedBy VARCHAR(50) NULL,
					 UpdatedBy VARCHAR(50) NULL,
					 IsActive BIT NULL,
					 IsDeleted BIT NULL,
					 WorkOrderMaterialsId BIGINT NULL,
					 Qty INT NULL,
					 QtyToShip INT NULL,
					 MasterCompanyId BIGINT NULL,
					 [Status] INT NULL,
					 PickedById BIGINT NULL,
					 ConfirmedById BIGINT NULL,
					 Memo VARCHAR(MAX) NULL,
					 IsConfirmed BIT NULL,
					 CodePrefixId BIGINT NULL,
					 CurrentNummber BIGINT NULL,
					 IsMPN BIT NULL,
					 StocklineId BIGINT NULL,
				)

				SELECT @SubWorkOrderStatusId  = Id FROM dbo.WorkOrderStatus WITH(NOLOCK) WHERE UPPER(StatusCode) = 'CLOSED'
				SELECT @ProvisionId  = ProvisionId FROM dbo.Provision WITH(NOLOCK) WHERE UPPER(StatusCode) = 'REPLACE'
				SELECT @MasterCompanyId  = MasterCompanyId FROM dbo.SubWorkOrder WITH(NOLOCK) WHERE SubWorkOrderId = @SubWorkOrderId
				

				IF(@IsCreate = 1)
				BEGIN
					UPDATE dbo.Stockline SET QuantityAvailable = QuantityAvailable - @SubWOPartQty WHERE StockLineId = @StocklineId
				END
				ELSE
				BEGIN
					IF((SELECT COUNT(1) FROM dbo.SubWorkOrderPartNumber WHERE SubWOPartNoId = @SubWorkOrderPartNoId AND SubWorkOrderStatusId = @SubWorkOrderStatusId ) > 0)
					BEGIN
						UPDATE dbo.Stockline SET QuantityAvailable = QuantityAvailable  + @SubWOPartQty WHERE StockLineId = @StocklineId
					END

					EXEC USP_CloseSubWorkOrder @WorkOrderId, @SubWorkOrderId, @WorkOrderMaterialsId, @StocklineId, @UpdatedById;
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
              , @AdhocComments     VARCHAR(150)    = 'USP_Reserve_ReleaseSubWorkOrderStockline' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = ' + ISNULL(@WorkOrderId, '') + ',
													   @Parameter2 = ' + ISNULL(@SubWorkOrderId,'') + ', 
													   @Parameter3 = ' + ISNULL(@WorkOrderMaterialsId,'') + ', 
													   @Parameter4 = ' + ISNULL(@StocklineId,'') + ', 
													   @Parameter5 = ' + ISNULL(@SubWorkOrderPartNoId ,'') +''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

              exec spLogException 
                       @DatabaseName			= @DatabaseName
                     , @AdhocComments			= @AdhocComments
                     , @ProcedureParameters		= @ProcedureParameters
                     , @ApplicationName			= @ApplicationName
                     , @ErrorLogID              = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
		END CATCH
END
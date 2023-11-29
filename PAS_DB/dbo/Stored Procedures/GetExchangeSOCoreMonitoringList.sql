/*************************************************************           
--EXEC GetExchangeSOCoreMonitoringList 10075
************************************************************************/
CREATE PROCEDURE [dbo].[GetExchangeSOCoreMonitoringList]
@ExchangeSalesOrderId bigint
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
		select DISTINCT RCT.ReceivingCustomerWorkId,IM.PartNumber,IM.PartDescription,MN.[Name],'' as 'RevisedPart',RCT.ExpDate,RCT.ItemMasterId,RCT.ManagementStructureId,IM.ManufacturerId,EXCHSO.MasterCompanyId,
		RCT.PartCertificationNumber,RCT.Quantity,RCT.ReceivingNumber,RCT.Reference,IM.RevisedPartId as 'RevisePartId',RCT.SerialNumber,RCT.StockLineId,RCT.TimeLifeCyclesId,CASE WHEN RCT.ReceivedDate is not null THEN RCT.ReceivedDate ELSE EXCHSOP.ReceivedDate END as ReceivedDate,RCT.CustReqDate,
		RCT.EmployeeName as 'ReceivedBy','' as 'StockLineNumber',EXCHSOP.CoreStatusId,EXCHSOP.CoreDueDate,EXCHSOP.ExchangeCorePrice as 'CorePrice',EXCHSOP.ExchangeSalesOrderPartId,EXCHSOP.ExchangeSalesOrderId,
		EXCHSOP.LetterSentDate,EXCHSOP.LetterTypeId,EXCHSOP.Memo,1 as 'isEditPart',EXCHSOP.ExpectedCoreSN as 'ExpectedSN',EXCHSOP.ExpecedCoreCond,EXCHSO.CoreAccepted from DBO.ExchangeSalesOrder EXCHSO
		INNER JOIN DBO.ExchangeSalesOrderPart EXCHSOP ON EXCHSO.ExchangeSalesOrderId = EXCHSOP.ExchangeSalesOrderId
		LEFT JOIN DBO.ReceivingCustomerWork RCT ON EXCHSO.ExchangeSalesOrderId = RCT.ExchangeSalesOrderId
		LEFT JOIN DBO.ItemMaster IM ON EXCHSOP.ItemMasterId = IM.ItemMasterId
		LEFT JOIN ItemMasterExchangeLoan IMEXCH ON IM.ItemMasterId = IMEXCH.ItemMasterId
		LEFT JOIN Stockline ST ON RCT.StockLineId = ST.StockLineId
		LEFT JOIN Manufacturer MN ON IM.ManufacturerId = MN.ManufacturerId
		LEFT JOIN ItemMaster ITM ON Im.ItemMasterId = RCT.RevisePartId
		WHERE EXCHSO.ExchangeSalesOrderId = @ExchangeSalesOrderId;
		
		Select EXCHCMD.LetterTypeId,EXCHCT.[Name],EXCHCMD.ExchangeSalesOrderId,EXCHCMD.LetterSentDate,EXCHSOP.ExchangeSalesOrderPartId,EXCHCMD.ExchangeCoreMonitoringDetailsId From DBO.ExchangeCoreMonitoringDetails EXCHCMD
		INNER JOIN DBO.ExchangeCoreLetterType EXCHCT ON EXCHCMD.LetterTypeId = EXCHCT.ExchangeCoreLetterTypeId
		INNER JOIN DBO.ExchangeSalesOrderPart EXCHSOP ON EXCHCMD.ExchangeSalesOrderId = EXCHSOP.ExchangeSalesOrderId
		WHERE EXCHCMD.ExchangeSalesOrderId = @ExchangeSalesOrderId;
    END TRY
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'GetExchangeSOCoreMonitoringList' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@ExchangeSalesOrderId, '') + ''
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
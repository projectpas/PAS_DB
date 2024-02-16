/*************************************************************
 ** File:     [RPT_GetExchangeSOCoreMonitoringList]
 ** Author:   Ekta Chandegra
 ** Description: 
 ** Purpose:
 ** Date:   12/06/2023
 ** PARAMETERS:         
 @ExchangeSalesOrderId BIGINT
 ** RETURN VALUE:
 **************************************************************
  ** Change History
 **************************************************************
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    12/06/2023   Ekta Chandegra  Created
	2    16 FEB 2024  BHARGAV SALIYA  Resolved Print Issue

 EXECUTE RPT_GetExchangeSOCoreMonitoringList 370,83
**************************************************************/ 
CREATE   PROCEDURE [dbo].[RPT_GetExchangeSOCoreMonitoringList]
	@ExchangeSalesOrderId BIGINT = NULL,
	@ExchangeCoreMonitoringDetailsId BIGINT = NULL
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
		select DISTINCT RCT.ReceivingCustomerWorkId,IM.PartNumber,IM.PartDescription,MN.[Name],'' as 'RevisedPart',RCT.ExpDate,RCT.ItemMasterId,RCT.ManagementStructureId,IM.ManufacturerId,EXCHSO.MasterCompanyId,
		RCT.PartCertificationNumber,RCT.Quantity,RCT.ReceivingNumber,RCT.Reference,IM.RevisedPartId as 'RevisePartId',RCT.SerialNumber,RCT.StockLineId,RCT.TimeLifeCyclesId,CASE WHEN RCT.ReceivedDate is not null THEN RCT.ReceivedDate ELSE EXCHSOP.ReceivedDate END as ReceivedDate,RCT.CustReqDate,
		RCT.EmployeeName as 'ReceivedBy','' as 'StockLineNumber',EXCHSOP.CoreStatusId,EXCHSOP.CoreDueDate,EXCHSOP.ExchangeCorePrice as 'CorePrice',EXCHSOP.ExchangeSalesOrderPartId,EXCHSOP.ExchangeSalesOrderId,
		EMD.LetterSentDate,EXCHSOP.LetterTypeId,EXCHSOP.Memo,1 as 'isEditPart',EXCHSOP.ExpectedCoreSN as 'ExpectedSN',
		EXCHSOP.ExpecedCoreCond,EXCHSO.CoreAccepted
		--,UPPER(EXCHSO.ExchangeSalesOrderNumber) as 'ExchangeSalesOrderNumber'
		,UPPER(EXCHCT.[Name]) as 'CoreLetterName',UPPER(EXCHSO.CustomerName) as 'CustomerName', 
		 CASE WHEN ISNULL(EXCHSOP.POId,0) != 0 THEN 'PO Num - ' + CAST(EXCHSOP.PONumber AS varchar) + ' ,' ELSE '' END as 'PO Num'
		 , 'Exchange Sales Order Number - ' + UPPER(EXCHSO.ExchangeSalesOrderNumber) + CASE WHEN ISNULL(EXCHSOP.POId,0) != 0 THEN ', PO Num - ' + CAST(EXCHSOP.PONumber AS varchar) ELSE '' END + (CASE WHEN ISNULL(IM.PartNumber,'') != '' THEN ', PN - ' + IM.PartNumber ELSE '' END) AS 'ExchangeSalesOrderNumber'


		from [DBO].ExchangeCoreMonitoringDetails EMD
		INNER JOIN [DBO].ExchangeSalesOrder EXCHSO ON EXCHSO.ExchangeSalesOrderId = EMD.ExchangeSalesOrderId
		INNER JOIN [DBO].ExchangeSalesOrderPart EXCHSOP ON EXCHSO.ExchangeSalesOrderId = EXCHSOP.ExchangeSalesOrderId
		LEFT JOIN [DBO].ExchangeCoreLetterType EXCHCT ON EMD.LetterTypeId = EXCHCT.ExchangeCoreLetterTypeId
		LEFT JOIN [DBO].ReceivingCustomerWork RCT ON EXCHSO.ExchangeSalesOrderId = RCT.ExchangeSalesOrderId
		LEFT JOIN [DBO].ItemMaster IM ON EXCHSOP.ItemMasterId = IM.ItemMasterId
		LEFT JOIN [DBO].ItemMasterExchangeLoan IMEXCH ON IM.ItemMasterId = IMEXCH.ItemMasterId
		LEFT JOIN [DBO].Stockline ST ON RCT.StockLineId = ST.StockLineId
		LEFT JOIN [DBO].Manufacturer MN ON IM.ManufacturerId = MN.ManufacturerId
		LEFT JOIN [DBO].ItemMaster ITM ON Im.ItemMasterId = RCT.RevisePartId
		WHERE EXCHSO.ExchangeSalesOrderId = @ExchangeSalesOrderId AND EMD.ExchangeCoreMonitoringDetailsId = @ExchangeCoreMonitoringDetailsId;
    END TRY
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'RPT_GetExchangeSOCoreMonitoringList' 
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
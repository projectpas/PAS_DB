--exec SearchExchangeSalesOrderCoreTrackingData 1,20,'ExchangeSalesOrderNumber',1,'','','','','','','','',0,1,0
CREATE PROCEDURE [dbo].[SearchExchangeSalesOrderCoreTrackingData]
	-- Add the parameters for the stored procedure here
	@PageNumber int=1,
	@PageSize int=10,
	@SortColumn varchar(50)='ExchangeSalesOrderNumber',
	@SortOrder int=1,
	@StatusID int=1,
	@GlobalFilter varchar(50) = '',
	@PartNumber varchar(50)=null,
	@PartDescription varchar(50)=null,
	@ExchangeSalesOrderNumber varchar(50)=null,
	@CustomerName varchar(50)=null,
	@ReceivingNumber varchar(50)=null,
	@Status varchar(50)=null,   
    @IsDeleted bit = null,
	@MasterCompanyId int = 1,
	@EmployeeId bigint,
	@WONum varchar(50)=null,
	@OpenDate datetime=null,
	@ReceivedDate datetime=null,
	@CoreDueDate datetime=null,
	@LetterSentDate datetime=null
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN
		DECLARE @RecordFrom int;
			SET @RecordFrom = (@PageNumber-1) * @PageSize;
			IF @IsDeleted is null
			Begin
				Set @IsDeleted=0
			End
			print @IsDeleted	
			IF @SortColumn is null
			Begin
				Set @SortColumn=Upper('ExchangeSalesOrderId')
			End 
			Else
			Begin 
				Set @SortColumn=Upper(@SortColumn)
			End
			
			If @StatusID=0
			Begin 
				Set @StatusID=null
			End 

			If @Status='0'
			Begin
				Set @Status=null
			End
			DECLARE @MSModuleID INT = 19; -- Exchange SalesOrder Management Structure Module ID
		-- Insert statements for procedure here
		;With Result AS(
			select exchso.ExchangeSalesOrderId,exchso.ExchangeSalesOrderNumber,exchso.CustomerId,cr.[Name] as 'CustomerName',rcw.ReceivingCustomerWorkId,im.partnumber as 'PartNumber',im.PartDescription,
				mnf.[Name] as 'Manufacturer',rcw.ExpDate as 'ExpDate',rcw.ItemMasterId as 'ItemMasterId',
				exchso.ManagementStructureId,im.ManufacturerId,exchso.MasterCompanyId,rcw.PartCertificationNumber,exchso.OpenDate,
				rcw.Quantity,rcw.ReceivingNumber,rcw.Reference,im.RevisedPartId,
				exchsop.ExpectedCoreSN as 'SerialNumber',rcw.StockLineId,rcw.TimeLifeCyclesId,rcw.ReceivedDate,
				rcw.CustReqDate,rcw.EmployeeName,exchsop.CoreStatusId,exchcms.[Name] as 'Status',CASE WHEN exchsop.CoreDueDate = null THEN exchsop.EntryDate ELSE exchsop.CoreDueDate END as 'CoreDueDate',
				exchsop.ExchangeCorePrice,exchsop.ExchangeSalesOrderPartId,exchsop.LetterSentDate as 'LetterSentDate',exchsop.LetterTypeId,exchclt.[Name] as'LetterType',
				exchsop.Memo,exchsop.ExpectedCoreSN,exchsop.ExpecedCoreCond,exchso.CoreAccepted,wo.WorkOrderId,wo.WorkOrderNum as 'WONum' from ExchangeSalesOrder exchso WITH (NOLOCK)
				inner join ExchangeSalesOrderPart exchsop WITH (NOLOCK) on exchso.ExchangeSalesOrderId = exchsop.ExchangeSalesOrderId
				inner join Customer cr WITH(NOLOCK) on exchso.CustomerId = cr.CustomerId
				left join ReceivingCustomerWork rcw WITH (NOLOCK) on exchso.ExchangeSalesOrderId = rcw.ExchangeSalesOrderId
				left join ItemMaster im WITH (NOLOCK) on exchsop.ItemMasterId = im.ItemMasterId
				left join ItemMasterExchangeLoan imexch WITH (NOLOCK) on im.ItemMasterId = imexch.ItemMasterId
				left join Stockline stl WITH (NOLOCK) on rcw.StockLineId = stl.StockLineId
				inner join Manufacturer mnf WITH (NOLOCK) on im.ManufacturerId = mnf.ManufacturerId
				left join ExchCoreMonitoringStatus exchcms WITH(NOLOCK) on exchsop.CoreStatusId = exchcms.ExchangeCoreMonitoringStatusId
				left join ExchangeCoreLetterType exchclt WITH(NOLOCK) on exchsop.LetterTypeId = exchclt.ExchangeCoreLetterTypeId
				left join WorkOrder wo WITH(NOLOCK) on rcw.WorkOrderId = wo.WorkOrderId
				where exchso.MasterCompanyId=@MasterCompanyId and (@StatusID is null or exchsop.CoreStatusId = @StatusID)
			),
			--ResultCount AS (Select COUNT(SalesOrderId) AS NumberOfItems FROM Result)
			FinalResult AS (
			SELECT ExchangeSalesOrderId,ExchangeSalesOrderNumber,CustomerId,CustomerName,ReceivingCustomerWorkId, PartNumber,PartDescription,
					Manufacturer, 
					ExpDate,ItemMasterId, ManagementStructureId, ManufacturerId, MasterCompanyId, PartCertificationNumber,OpenDate,
					Quantity,SerialNumber,
					ReceivingNumber, Reference,
					RevisedPartId,ReceivedDate,LetterSentDate,LetterTypeId,LetterType,
					CustReqDate,
					EmployeeName,CoreStatusId,[Status],CoreDueDate, Memo, 
					ExpectedCoreSN, ExpecedCoreCond, CoreAccepted,WorkOrderId,WONum FROM Result
			where (
				(@GlobalFilter <>'' AND ((PartNumber like '%' +@GlobalFilter+'%' ) OR 
						(PartDescription like '%' +@GlobalFilter+'%') OR
						(ReceivingNumber like '%' +@GlobalFilter+'%') OR
						(CustomerName like '%' +@GlobalFilter+'%') OR
						(ExchangeSalesOrderNumber like '%' +@GlobalFilter+'%')OR
						(WONum like '%' +@GlobalFilter+'%') 
						))
						OR   
						(@GlobalFilter='' AND (IsNull(@PartNumber,'') ='' OR PartNumber like  '%'+ @PartNumber+'%') and 
						(IsNull(@PartDescription,'') ='' OR PartDescription like '%'+@PartDescription+'%') and
						(IsNull(@CustomerName,'') ='' OR CustomerName like  '%'+@CustomerName+'%') and
						(IsNull(@ReceivingNumber,'') ='' OR ReceivingNumber like '%'+@ReceivingNumber+'%') and
						(IsNull(@ExchangeSalesOrderNumber,'') ='' OR ExchangeSalesOrderNumber like '%'+ @ExchangeSalesOrderNumber+'%') and
						(IsNull(@WONum,'') ='' OR WONum like '%'+ @WONum+'%') and
						(@OpenDate is  null or Cast(OpenDate as date)=Cast(@OpenDate as date)) and
						(@ReceivedDate is  null or Cast(ReceivedDate as date)=Cast(@ReceivedDate as date)) and
						(@CoreDueDate is  null or Cast(CoreDueDate as date)=Cast(@CoreDueDate as date)) and
						(@LetterSentDate is  null or Cast(LetterSentDate as date)=Cast(@LetterSentDate as date))
						))
						),
					ResultCount AS (Select COUNT(ExchangeSalesOrderId) AS NumberOfItems FROM FinalResult)
					SELECT ExchangeSalesOrderId,ExchangeSalesOrderNumber,CustomerId,CustomerName,
					ReceivingCustomerWorkId,OpenDate,SerialNumber,
					PartNumber, PartDescription, CustomerName, Manufacturer, ExpDate, ItemMasterId,
					ManagementStructureId,LetterSentDate,LetterTypeId,LetterType,
					ManufacturerId, MasterCompanyId,PartCertificationNumber,Quantity,
					ReceivingNumber, Reference, RevisedPartId,ReceivedDate,CustReqDate, EmployeeName, CoreStatusId,[Status],CoreDueDate,
					Memo, ExpectedCoreSN, ExpecedCoreCond,CoreAccepted,WorkOrderId,WONum,NumberOfItems FROM FinalResult, ResultCount
					ORDER BY  
				CASE WHEN (@SortOrder=1 and @SortColumn='EXCHANGESALESORDERID')  THEN ExchangeSalesOrderId END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='PARTNUMBER')  THEN PartNumber END ASC,
				CASE WHEN (@SortOrder=1 and @SortColumn='PARTDESCRIPTION')  THEN PartDescription END ASC,
				CASE WHEN (@SortOrder=1 and @SortColumn='CUSTOMERNAME')  THEN CustomerName END ASC,
				CASE WHEN (@SortOrder=1 and @SortColumn='EXCHANGESALESORDERNUMBER')  THEN ExchangeSalesOrderNumber END ASC,
		        CASE WHEN (@SortOrder=-1 and @SortColumn='EXCHANGESALESORDERID')  THEN PartNumber END DESC,
		        CASE WHEN (@SortOrder=-1 and @SortColumn='PARTDESCRIPTION')  THEN PartDescription END DESC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='CUSTOMERNAME')  THEN CustomerName END DESC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='EXCHANGESALESORDERNUMBER')  THEN ExchangeSalesOrderNumber END DESC
				OFFSET @RecordFrom ROWS 
				FETCH NEXT @PageSize ROWS ONLY
				Print @SortOrder
	END
	COMMIT  TRANSACTION
	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'SearchExchangeSalesOrderData' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@PageNumber, '') + ''
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
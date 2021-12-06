CREATE PROCEDURE [dbo].[SearchExchangeQuoteData]
	-- Add the parameters for the stored procedure here
	@PageNumber int=1,
	@PageSize int=10,
	@SortColumn varchar(50)='ExchangeQuoteId',
	@SortOrder int=1,
	@StatusID int=1,
	@GlobalFilter varchar(50) = '',
	@ExchangeQuoteNumber varchar(50)=null,
	--@SalesOrderNumber varchar(50)=null,
	@CustomerName varchar(50)=null,
	@Status varchar(50)=null,
    @OpenDate datetime=null,
	@QuoteExpireDate datetime=null,
	--@EstimateShipDate datetime=null,
    @SalesPerson varchar(50)=null,
    @PriorityType varchar(50)=null,
	@CustomerRequestDateType varchar(50)=null,
	@EstimateShipDateType varchar(50)=null,
	--@CustomerRequestDate datetime=null,
	@PromiseDate datetime=null,
    @PartNumberType varchar(50)=null,
    @PartDescriptionType varchar(50)=null,
    @CustomerReference varchar(50)=null,
    --@CustomerType varchar(50)=null,
	@VersionNumber varchar(50)=null,
    @CreatedDate datetime=null,
    @UpdatedDate  datetime=null,
    @IsDeleted bit = null,
	@CreatedBy varchar(50)=null,
	@UpdatedBy varchar(50)=null,
	@MasterCompanyId int = 1
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
					Set @SortColumn=Upper('CreatedDate')
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
			-- Insert statements for procedure here
			;With Result AS(
				Select EQ.ExchangeQuoteId, EQ.ExchangeQuoteNumber, EQ.OpenDate as 'OpenDate', EQ.QuoteExpireDate as 'QuoteExpireDate', C.CustomerId, C.Name as 'CustomerName', MST.Name as 'Status',
				--ISNULL(SP.NetSales,0) as 'QuoteAmount',ISNULL(SP.UnitCost, 0) as 'UnitCost', 
				ISNULL(SP.CustomerRequestDate, '0001-01-01') as 'CustomerRequestDate',
				ISNULL(SP.CustomerRequestDate, '0001-01-01') as 'CustomerRequestDateType',
				EQ.StatusId, EQ.CustomerReference, IsNull(P.Description, '') as 'Priority', IsNull(P.Description, '') as 'PriorityType',
				(E.FirstName+' '+E.LastName)as SalesPerson,
				IsNull(IM.partnumber,'') as 'PartNumber', IsNull(IM.partnumber,'') as 'PartNumberType', IsNull(im.PartDescription,'') as 'PartDescription', IsNull(im.PartDescription,'') as 'PartDescriptionType',
				EQ.CreatedDate, EQ.UpdatedDate, EQ.UpdatedBy, EQ.CreatedBy, ISNULL(SP.EstimatedShipDate, '0001-01-01') as 'EstimateShipDate', ISNULL(SP.EstimatedShipDate, '0001-01-01') as 'EstimateShipDateType', ISNULL(SP.PromisedDate, '0001-01-01') as 'PromiseDate',
				--ISNULL(EQ.ShippedDate, '0001-01-01') as 'ShippedDate', 
				EQ.IsDeleted
				, dbo.GenearteVersionNumber(EQ.Version) as 'VersionNumber'
				from ExchangeQuote EQ WITH (NOLOCK)
				Inner Join ExchangeStatus MST WITH (NOLOCK) on EQ.StatusId = MST.ExchangeStatusId
				Inner Join Customer C WITH (NOLOCK) on C.CustomerId = EQ.CustomerId
				Left Join ExchangeQuotePart SP WITH (NOLOCK) on EQ.ExchangeQuoteId = SP.ExchangeQuoteId and SP.IsDeleted = 0
				Left Join ItemMaster IM WITH (NOLOCK) on Im.ItemMasterId = SP.ItemMasterId
				Left Join Employee E WITH (NOLOCK) on  E.EmployeeId = EQ.SalesPersonId
				Left Join Priority P WITH (NOLOCK) on EQ.PriorityId=P.PriorityId
				Where (EQ.IsDeleted = @IsDeleted) and (@StatusID is null or EQ.StatusId = @StatusID)
				AND EQ.MasterCompanyId = @MasterCompanyId
				Group By EQ.ExchangeQuoteId, ExchangeQuoteNumber, EQ.OpenDate,EQ.QuoteExpireDate, C.CustomerId, C.Name, 
				MST.Name, 
				--SP.NetSales, SP.UnitCost,
				SP.CustomerRequestDate, EQ.StatusId, EQ.CustomerReference,
				P.Description, E.FirstName, E.LastName,
				IM.partnumber, IM.PartDescription,
				EQ.CreatedDate, EQ.UpdatedDate, EQ.UpdatedBy, EQ.CreatedBy, SP.EstimatedShipDate, SP.PromisedDate, SP.CustomerRequestDate, EQ.IsDeleted
				,EQ.Version
				),
				--ResultCount AS (Select COUNT(SalesOrderId) AS NumberOfItems FROM Result)
				FinalResult AS (
				SELECT ExchangeQuoteId, ExchangeQuoteNumber,
						VersionNumber, 
						OpenDate,QuoteExpireDate, CustomerId, CustomerName, CustomerReference, Priority, 
						PriorityType,
						--QuoteAmount, UnitCost,
						CustomerRequestDate,
						--RequestedDateType,
						EstimateShipDate,CustomerRequestDateType, EstimateShipDateType, PromiseDate, 
						SalesPerson, Status, StatusId,
						PartNumber, PartNumberType, PartDescription, PartDescriptionType,
						CreatedDate, UpdatedDate, CreatedBy, UpdatedBy FROM Result
				where (
					(@GlobalFilter <>'' AND ((ExchangeQuoteNumber like '%' +@GlobalFilter+'%' ) OR 
							--(SalesOrderNumber like '%' +@GlobalFilter+'%') OR
							(OpenDate like '%' +@GlobalFilter+'%') OR
							(CustomerName like '%' +@GlobalFilter+'%') OR
							(SalesPerson like '%' +@GlobalFilter+'%') OR
							(VersionNumber like '%'+@GlobalFilter+'%') OR
							(CustomerReference like '%' +@GlobalFilter+'%') OR
							(PriorityType like '%' +@GlobalFilter+'%') OR
							(CustomerRequestDateType like '%' +@GlobalFilter+'%') OR
							(QuoteExpireDate like '%' +@GlobalFilter+'%') OR
							(EstimateShipDateType like '%' +@GlobalFilter+'%') OR
							(EstimateShipDate like '%' +@GlobalFilter+'%') OR
							(PromiseDate like '%' +@GlobalFilter+'%') OR
							(PartNumberType like '%' +@GlobalFilter+'%') OR
							(PartDescriptionType like '%' +@GlobalFilter+'%') OR
							(CreatedDate like '%' +@GlobalFilter+'%') OR
							(UpdatedDate like '%' +@GlobalFilter+'%') OR
							(Status like '%' +@GlobalFilter+'%')
							))
							OR   
							(@GlobalFilter='' AND (IsNull(@ExchangeQuoteNumber,'') ='' OR ExchangeQuoteNumber like  '%'+ @ExchangeQuoteNumber+'%') and 
							--(IsNull(@SalesOrderNumber,'') ='' OR SalesOrderNumber like '%'+@SalesOrderNumber+'%') and
							(IsNull(@CustomerName,'') ='' OR CustomerName like  '%'+@CustomerName+'%') and
							(IsNull(@CustomerReference,'') ='' OR CustomerReference like '%'+@CustomerReference+'%') and
							(IsNull(@PriorityType,'') ='' OR PriorityType like '%'+ @PriorityType+'%') and
							(IsNull(@VersionNumber,'') ='' OR VersionNumber like '%'+@VersionNumber+'%') and
							(IsNull(@SalesPerson,'') ='' OR SalesPerson like '%'+ @SalesPerson+'%') and
							(IsNull(@OpenDate,'') ='' OR Cast(OpenDate as Date) = Cast(@OpenDate as date)) and
							(IsNull(@QuoteExpireDate,'') ='' OR Cast(QuoteExpireDate as Date) = Cast(@QuoteExpireDate as date)) and
							(IsNull(@CustomerRequestDateType,'') ='' OR CustomerRequestDateType like '%'+ @CustomerRequestDateType +'%') and
							(IsNull(@EstimateShipDateType,'') ='' OR EstimateShipDateType like '%'+ @EstimateShipDateType +'%') and
							--(IsNull(@QuoteDate,'') ='' OR Cast(QuoteDate as Date) = Cast(@QuoteDate as date)) and
							--(IsNull(@ShippedDate,'') ='' OR Cast(ShippedDate as Date) = Cast(@ShippedDate as date)) and
							--(IsNull(@CustomerRequestDate,'') ='' OR Cast(CustomerRequestDate as Date) = Cast(@CustomerRequestDate as date)) and
							(IsNull(@PromiseDate,'') ='' OR Cast(PromiseDate as Date) = Cast(@PromiseDate as date)) and
							--(IsNull(@EstimateShipDate,'') ='' OR Cast(EstimateShipDate as Date) = Cast(@EstimateShipDate as date)) and
							(IsNull(@PartNumberType,'') ='' OR PartNumberType like '%'+@PartNumberType+'%') and
							(IsNull(@PartDescriptionType,'') ='' OR PartDescriptionType like '%'+@PartDescriptionType+'%') and
							(IsNull(@CreatedBy,'') ='' OR CreatedBy like '%'+ @CreatedBy+'%') and
							(IsNull(@UpdatedBy,'') ='' OR UpdatedBy like '%'+ @UpdatedBy+'%') and
							(IsNull(@CreatedDate,'') ='' OR Cast(CreatedDate as Date)=Cast(@CreatedDate as date)) and
							(IsNull(@UpdatedDate,'') ='' OR Cast(UpdatedDate as date)=Cast(@UpdatedDate as date)) and
							(IsNull(@Status,'') ='' OR Status like  '%'+@Status+'%'))
							)
							),
						ResultCount AS (Select COUNT(ExchangeQuoteId) AS NumberOfItems FROM FinalResult)
						SELECT ExchangeQuoteId, ExchangeQuoteNumber,
						VersionNumber,
						OpenDate, CustomerId, CustomerName, CustomerReference, Priority, 
						PriorityType,
						--QuoteAmount, UnitCost,
						CustomerRequestDate, CustomerRequestDateType, QuoteExpireDate, EstimateShipDate, EstimateShipDateType, PromiseDate, 
						--ShippedDate,
						SalesPerson, Status, StatusId,
						PartNumber, PartNumberType, PartDescription, PartDescriptionType,
						CreatedDate, UpdatedDate, CreatedBy, UpdatedBy, NumberOfItems FROM FinalResult, ResultCount

						ORDER BY  
					CASE WHEN (@SortOrder=1 and @SortColumn='EXCHANGEQUOTEID')  THEN ExchangeQuoteId END DESC,
					CASE WHEN (@SortOrder=1 and @SortColumn='EXCHANGEQUOTENUMBER')  THEN ExchangeQuoteNumber END ASC,
					--CASE WHEN (@SortOrder=1 and @SortColumn='SALESORDERQUOTENUMBER')  THEN SalesOrderQuoteNumber END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='VERSIONNUMBER')  THEN VersionNumber END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='QUOTEEXPIREDATE')  THEN QuoteExpireDate END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='STATUS')  THEN Status END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='PARTNUMBERTYPE')  THEN PartNumberType END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='PARTDESCRIPTIONTYPE')  THEN PartDescriptionType END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='CUSTOMERNAME')  THEN CustomerName END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='CUSTOMERREFERENCE')  THEN CustomerReference END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='PRIORITYTYPE')  THEN PriorityType END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='OPENDATE')  THEN OpenDate END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='REQUESTEDDATE')  THEN CustomerRequestDate END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='ESTIMATEDSHIPDATE')  THEN EstimateShipDate END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='SALESPERSON')  THEN SalesPerson END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='CREATEDDATE')  THEN CreatedDate END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='UPDATEDDATE')  THEN UpdatedDate END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='CREATEDBY')  THEN CreatedBy END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='UPDATEDBY')  THEN UpdatedBy END ASC,

			        CASE WHEN (@SortOrder=-1 and @SortColumn='EXCHANGEQUOTEID')  THEN ExchangeQuoteId END DESC,
			        CASE WHEN (@SortOrder=-1 and @SortColumn='EXCHANGEQUOTENUMBER')  THEN ExchangeQuoteNumber END DESC,
					--CASE WHEN (@SortOrder=-1 and @SortColumn='SALESORDERQUOTENUMBER')  THEN SalesOrderQuoteNumber END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='VERSIONNUMBER')  THEN VersionNumber END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='QUOTEEXPIREDATE')  THEN QuoteExpireDate END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='STATUS')  THEN Status END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='PARTNUMBERTYPE')  THEN PartNumberType END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='PARTDESCRIPTIONTYPE')  THEN PartDescriptionType END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='CUSTOMERNAME')  THEN CustomerName END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='CUSTOMERREFERENCE')  THEN CustomerReference END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='PRIORITYTYPE')  THEN PriorityType END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='OPENDATE')  THEN OpenDate END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='REQUESTEDDATE')  THEN CustomerRequestDate END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='ESTIMATEDSHIPDATE')  THEN EstimateShipDate END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='SALESPERSON')  THEN SalesPerson END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='CREATEDDATE')  THEN CreatedDate END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='UPDATEDDATE')  THEN UpdatedDate END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='CREATEDBY')  THEN CreatedBy END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='UPDATEDBY')  THEN UpdatedBy END DESC
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
              , @AdhocComments     VARCHAR(150)    = 'SearchExchangeQuoteData' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@PageNumber, '') + ''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
              exec spLogException 
                       @DatabaseName           =  @DatabaseName
                     , @AdhocComments          =  @AdhocComments
                     , @ProcedureParameters	   =  @ProcedureParameters
                     , @ApplicationName        =  @ApplicationName
                     , @ErrorLogID             =  @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
		END CATCH
END
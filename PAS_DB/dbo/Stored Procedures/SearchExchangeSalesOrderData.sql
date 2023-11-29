/*************************************************************             
 ** File:   [SearchExchangeSalesOrderData]             
 ** Author:    
 ** Description: Get Search Data for ExchangeSalesOrderList   
 ** Purpose:           
 ** Date:     
           
 ** RETURN VALUE:             
 **************************************************************             
 ** Change History             
 **************************************************************             
 ** PR   Date         Author             Change Description              
 ** --   --------     -------           --------------------------------            
    1    16/08/2023   Ekta Chandegra     Convert text into uppercase   
**************************************************************/   
CREATE     PROCEDURE [dbo].[SearchExchangeSalesOrderData]
-- Add the parameters for the stored procedure here
@PageNumber int=1,
@PageSize int=10,
@SortColumn varchar(50)='ExchangeSalesOrderId',
@SortOrder int=1,
@StatusID int=1,
@GlobalFilter varchar(50) = '',
@ExchangeQuoteNumber varchar(50)=null,
@ExchangeSalesOrderNumber varchar(50)=null,
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
@MasterCompanyId int = 1,
@EmployeeId bigint,
@ManufacturerName varchar(50)=null
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

	BEGIN TRY
	--BEGIN TRANSACTION
	--BEGIN
		DECLARE @RecordFrom int;
			SET @RecordFrom = (@PageNumber-1) * @PageSize;
			IF @IsDeleted IS NULL
			BEGIN
				SET @IsDeleted=0
			END			
			IF @SortColumn IS NULL
			BEGIN
				SET @SortColumn=UPPER('CreatedDate')
			End 
			Else
			BEGIN 
				SET @SortColumn=UPPER(@SortColumn)
			End
			
			IF @StatusID=0
			BEGIN 
				Set @StatusID=null
			End 

			IF @Status='0'
			BEGIN
				Set @Status=null
			End
			DECLARE @MSModuleID INT = 19; -- Exchange SalesOrder Management Structure Module ID
		-- Insert statements for procedure here
		;WITH Result AS(
			SELECT EQ.ExchangeSalesOrderId,
			       EQ.ExchangeSalesOrderNumber, 
				   EXQ.ExchangeQuoteNumber, 
				   EQ.OpenDate AS 'OpenDate', 
				   EXQ.QuoteExpireDate AS 'QuoteExpireDate', 
				   C.CustomerId, 
				   C.[Name] AS 'CustomerName', 
				   MST.[Name] AS 'Status',
			       --ISNULL(SP.NetSales,0) as 'QuoteAmount',ISNULL(SP.UnitCost, 0) as 'UnitCost', 
			      ISNULL(SP.CustomerRequestDate, '0001-01-01') AS 'CustomerRequestDate',
			      ISNULL(SP.CustomerRequestDate, '0001-01-01') AS 'CustomerRequestDateType',
			      EQ.StatusId, 
				  EQ.CustomerReference, 
				  ISNULL(P.[Description], '') AS 'Priority', 
				  ISNULL(P.[Description], '') AS 'PriorityType',
			      (E.FirstName+' '+E.LastName) AS SalesPerson,
			      ISNULL(IM.partnumber,'') AS 'PartNumber', 
			      ISNULL(im.ManufacturerName,'') AS 'ManufacturerName',
			      ISNULL(IM.partnumber,'') AS 'PartNumberType', 
				  ISNULL(im.PartDescription,'') AS 'PartDescription', 
				  ISNULL(im.PartDescription,'') AS 'PartDescriptionType',
			      EQ.CreatedDate, 
				  EQ.UpdatedDate, 
				  EQ.UpdatedBy, 
				  EQ.CreatedBy, 
				  ISNULL(SP.EstimatedShipDate, '0001-01-01') AS 'EstimateShipDate', 
				  ISNULL(SP.EstimatedShipDate, '0001-01-01') AS 'EstimateShipDateType', 
				  ISNULL(SP.PromisedDate, '0001-01-01') AS 'PromiseDate',
			      --ISNULL(EQ.ShippedDate, '0001-01-01') as 'ShippedDate', 
			      EQ.IsDeleted,
			      dbo.GenearteVersionNumber(EQ.Version) AS 'VersionNumber'
			FROM [dbo].[ExchangeSalesOrder] EQ WITH (NOLOCK)
			INNER JOIN [dbo].[ExchangeStatus] MST WITH (NOLOCK) on EQ.StatusId = MST.ExchangeStatusId
			INNER JOIN [dbo].[Customer] C WITH (NOLOCK) on C.CustomerId = EQ.CustomerId
			LEFT JOIN  [dbo].[ExchangeSalesOrderPart] SP WITH (NOLOCK) on EQ.ExchangeSalesOrderId = SP.ExchangeSalesOrderId and SP.IsDeleted = 0
			LEFT JOIN  [dbo].[ExchangeQuote] EXQ WITH (NOLOCK) on EXQ.ExchangeQuoteId = EQ.ExchangeQuoteId
			LEFT JOIN  [dbo].[ItemMaster] IM WITH (NOLOCK) on Im.ItemMasterId = SP.ItemMasterId
			LEFT JOIN  [dbo].[Employee] E WITH (NOLOCK) on  E.EmployeeId = EQ.SalesPersonId
			LEFT JOIN  [dbo].[Priority] P WITH (NOLOCK) on EXQ.PriorityId=P.PriorityId			
			INNER JOIN [dbo].[ExchangeManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @MSModuleID AND MSD.ReferenceID = EQ.ExchangeSalesOrderId
			INNER JOIN [dbo].[RoleManagementStructure] RMS WITH (NOLOCK) ON EQ.ManagementStructureId = RMS.EntityStructureId
			INNER JOIN [dbo].[EmployeeUserRole] EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId

			WHERE EQ.MasterCompanyId = @MasterCompanyId AND (EQ.IsDeleted = @IsDeleted) AND (@StatusID IS NULL OR EQ.StatusId = @StatusID)
			 
			GROUP BY EQ.ExchangeSalesOrderId,ExchangeSalesOrderNumber, EXQ.ExchangeQuoteNumber, EQ.OpenDate,EXQ.QuoteExpireDate, C.CustomerId, C.Name, 
			MST.Name, 
			--SP.NetSales, SP.UnitCost,
			SP.CustomerRequestDate, EQ.StatusId, EQ.CustomerReference,
			P.Description, E.FirstName, E.LastName,
			IM.partnumber, IM.ManufacturerName,IM.PartDescription,
			EQ.CreatedDate, EQ.UpdatedDate, EQ.UpdatedBy, EQ.CreatedBy, SP.EstimatedShipDate, SP.PromisedDate, SP.CustomerRequestDate, EQ.IsDeleted
			,EQ.Version
			),
			--ResultCount AS (Select COUNT(SalesOrderId) AS NumberOfItems FROM Result)
			FinalResult AS (
			SELECT ExchangeSalesOrderId,ExchangeSalesOrderNumber, ExchangeQuoteNumber,
					VersionNumber, 
					OpenDate,QuoteExpireDate, CustomerId, CustomerName, CustomerReference, Priority, 
					PriorityType,
					--QuoteAmount, UnitCost,
					CustomerRequestDate,
					--RequestedDateType,
					EstimateShipDate,CustomerRequestDateType, EstimateShipDateType, PromiseDate, 
					SalesPerson, Status, StatusId,
					PartNumber,ManufacturerName, PartNumberType, PartDescription, PartDescriptionType,
					CreatedDate, UpdatedDate, CreatedBy, UpdatedBy FROM Result
			WHERE (
				        (@GlobalFilter <>'' AND ((ExchangeQuoteNumber LIKE '%' +@GlobalFilter+'%' ) OR 
						(ExchangeSalesOrderNumber LIKE '%' +@GlobalFilter+'%') OR
						(OpenDate LIKE '%' +@GlobalFilter+'%') OR
						(CustomerName LIKE '%' +@GlobalFilter+'%') OR
						(SalesPerson LIKE '%' +@GlobalFilter+'%') OR
						(VersionNumber LIKE '%'+@GlobalFilter+'%') OR
						(CustomerReference LIKE '%' +@GlobalFilter+'%') OR
						(PriorityType LIKE '%' +@GlobalFilter+'%') OR
						(CustomerRequestDateType LIKE '%' +@GlobalFilter+'%') OR
						(QuoteExpireDate LIKE '%' +@GlobalFilter+'%') OR
						(EstimateShipDateType LIKE '%' +@GlobalFilter+'%') OR
						(EstimateShipDate LIKE '%' +@GlobalFilter+'%') OR
						(PromiseDate LIKE '%' +@GlobalFilter+'%') OR
						(PartNumberType LIKE '%' +@GlobalFilter+'%') OR
						(ManufacturerName LIKE '%' +@GlobalFilter+'%') OR
						(PartDescriptionType LIKE '%' +@GlobalFilter+'%') OR
						(CreatedDate LIKE '%' +@GlobalFilter+'%') OR
						(UpdatedDate LIKE '%' +@GlobalFilter+'%') OR
						(Status LIKE '%' +@GlobalFilter+'%')))
						OR   
						(@GlobalFilter='' AND (ISNULL(@ExchangeQuoteNumber,'') ='' OR ExchangeQuoteNumber LIKE  '%'+ @ExchangeQuoteNumber+'%') AND 
						(ISNULL(@ExchangeSalesOrderNumber,'') ='' OR ExchangeSalesOrderNumber LIKE '%'+@ExchangeSalesOrderNumber+'%') AND
						(ISNULL(@CustomerName,'') ='' OR CustomerName LIKE  '%'+@CustomerName+'%') AND
						(ISNULL(@ManufacturerName,'') ='' OR ManufacturerName LIKE  '%'+ @ManufacturerName +'%') AND
						(ISNULL(@CustomerReference,'') ='' OR CustomerReference LIKE '%'+@CustomerReference+'%') AND
						(ISNULL(@PriorityType,'') ='' OR PriorityType LIKE '%'+ @PriorityType+'%') AND
						(ISNULL(@VersionNumber,'') ='' OR VersionNumber LIKE '%'+@VersionNumber+'%') AND
						(ISNULL(@SalesPerson,'') ='' OR SalesPerson LIKE '%'+ @SalesPerson+'%') AND
						(ISNULL(@OpenDate,'') ='' OR Cast(OpenDate as Date) = Cast(@OpenDate as date)) AND
						(ISNULL(@QuoteExpireDate,'') ='' OR Cast(QuoteExpireDate as Date) = Cast(@QuoteExpireDate as date)) and
						(ISNULL(@CustomerRequestDateType,'') ='' OR CustomerRequestDateType LIKE '%'+ @CustomerRequestDateType +'%') AND
						(ISNULL(@EstimateShipDateType,'') ='' OR EstimateShipDateType LIKE '%'+ @EstimateShipDateType +'%') AND
						--(IsNull(@QuoteDate,'') ='' OR Cast(QuoteDate as Date) = Cast(@QuoteDate as date)) and
						--(IsNull(@ShippedDate,'') ='' OR Cast(ShippedDate as Date) = Cast(@ShippedDate as date)) and
						--(IsNull(@CustomerRequestDate,'') ='' OR Cast(CustomerRequestDate as Date) = Cast(@CustomerRequestDate as date)) and
						(ISNULL(@PromiseDate,'') ='' OR Cast(PromiseDate as Date) = Cast(@PromiseDate as date)) AND
						--(IsNull(@EstimateShipDate,'') ='' OR Cast(EstimateShipDate as Date) = Cast(@EstimateShipDate as date)) and
						(ISNULL(@PartNumberType,'') ='' OR PartNumberType LIKE '%'+@PartNumberType+'%') AND
						(ISNULL(@PartDescriptionType,'') ='' OR PartDescriptionType like '%'+@PartDescriptionType+'%') AND
						(ISNULL(@CreatedBy,'') ='' OR CreatedBy LIKE '%'+ @CreatedBy+'%') AND
						(ISNULL(@UpdatedBy,'') ='' OR UpdatedBy LIKE '%'+ @UpdatedBy+'%') AND
						(ISNULL(@CreatedDate,'') ='' OR Cast(CreatedDate as Date)=Cast(@CreatedDate as date)) AND
						(ISNULL(@UpdatedDate,'') ='' OR Cast(UpdatedDate as date)=Cast(@UpdatedDate as date)) AND
						(ISNULL(@Status,'') ='' OR Status LIKE  '%'+@Status+'%')))),

					ResultCount AS (SELECT COUNT(ExchangeSalesOrderId) AS NumberOfItems FROM FinalResult)
					SELECT ExchangeSalesOrderId,UPPER(ExchangeSalesOrderNumber) 'ExchangeSalesOrderNumber', UPPER(ExchangeQuoteNumber) 'ExchangeQuoteNumber',
					UPPER(VersionNumber) 'VersionNumber',
					OpenDate, CustomerId, UPPER(CustomerName) 'CustomerName', UPPER(CustomerReference) 'CustomerReference', UPPER(Priority) 'Priority', 
					UPPER(PriorityType) 'PriorityType',
					--QuoteAmount, UnitCost,
					CustomerRequestDate, CustomerRequestDateType, QuoteExpireDate, EstimateShipDate, EstimateShipDateType, PromiseDate, 
					--ShippedDate,
					UPPER(SalesPerson) 'SalesPerson', UPPER(Status) 'Status', StatusId,
					UPPER(PartNumber) 'PartNumber',UPPER(ManufacturerName) 'ManufacturerName', UPPER(PartNumberType) 'PartNumberType', UPPER(PartDescription) 'PartDescription', UPPER(PartDescriptionType) 'PartDescriptionType',
					CreatedDate, UpdatedDate, UPPER(CreatedBy) 'CreatedBy', UPPER(UpdatedBy) 'UpdatedBy', NumberOfItems FROM FinalResult, ResultCount

					ORDER BY  
				CASE WHEN (@SortOrder=1 and @SortColumn='EXCHANGESALESORDERID')  THEN ExchangeSalesOrderId END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='EXCHANGEQUOTENUMBER')  THEN ExchangeQuoteNumber END ASC,
				CASE WHEN (@SortOrder=1 and @SortColumn='EXCHANGESALESORDERNUMBER')  THEN ExchangeSalesOrderNumber END ASC,
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
				CASE WHEN (@SortOrder=1 and @SortColumn='MANUFACTURERNAME')  THEN ManufacturerName END ASC,

		        CASE WHEN (@SortOrder=-1 and @SortColumn='EXCHANGESALESORDERID')  THEN ExchangeSalesOrderId END DESC,
		        CASE WHEN (@SortOrder=-1 and @SortColumn='EXCHANGEQUOTENUMBER')  THEN ExchangeQuoteNumber END DESC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='EXCHANGESALESORDERNUMBER')  THEN ExchangeSalesOrderNumber END DESC,
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
				CASE WHEN (@SortOrder=-1 and @SortColumn='UPDATEDBY')  THEN UpdatedBy END DESC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='MANUFACTURERNAME')  THEN ManufacturerName END DESC
				OFFSET @RecordFrom ROWS 
				FETCH NEXT @PageSize ROWS ONLY
				Print @SortOrder
	--END
	--COMMIT  TRANSACTION
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
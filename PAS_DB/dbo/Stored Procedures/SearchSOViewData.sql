-- =============================================
-- Author:		Vishal Suthar
-- Create date: 18-Dec-2020
-- Description:	Get Search Data for SO View
-- =============================================
CREATE PROCEDURE [dbo].[SearchSOViewData]
	-- Add the parameters for the stored procedure here
	@PageNumber int,
	@PageSize int,
	@SortColumn varchar(50)=null,
	@SortOrder int,
	@StatusID int,
	@GlobalFilter varchar(50) = null,
	@SOQNumber varchar(50)=null,
	@SalesOrderNumber varchar(50)=null,
	@CustomerName varchar(50)=null,
	@Status varchar(50)=null,
    @QuoteAmount numeric(18,4)=null,
    @SoAmount numeric(18,4)=null,
    @QuoteDate datetime=null,
    @SalesPerson varchar(50)=null,
    @PriorityType varchar(50)=null,
    @PartNumberType varchar(50)=null,
    @PartDescriptionType varchar(50)=null,
    @CustomerReference varchar(50)=null,
    @CustomerType varchar(50)=null,
	@VersionNumber varchar(50)=null,
    @CreatedDate datetime=null,
    @UpdatedDate  datetime=null,
	@CreatedBy  varchar(50)=null,
	@UpdatedBy  varchar(50)=null,
    @IsDeleted bit= null,
	@MasterCompanyId int = null,
	@OpenDate datetime=null,
	@ShippedDate varchar(50)=null,
	@RequestedDateType varchar(50)=null,
	@EstimatedShipDateType varchar(50)=null
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
				SET @RecordFrom = (@PageNumber-1)*@PageSize;
				IF @IsDeleted is null
				Begin
					Set @IsDeleted=0
				End
				print @IsDeleted	
				IF @SortColumn is null
				Begin
					Set @SortColumn=Upper('SalesOrderId')
				End 
				Else
				Begin 
					Set @SortColumn=Upper(@SortColumn)
				End

				If @QuoteAmount=0
				Begin 
					Set @QuoteAmount=null
				End
		
				If @SoAmount=0
				Begin 
					Set @SoAmount=null
				End


				If @StatusID=0
				Begin 
					Set @StatusID=null
				End 

				If @Status='0'
				Begin
					Set @Status=null
				End

				;With Main AS(
						Select SO.SalesOrderId, SO.SalesOrderNumber, SOQ.SalesOrderQuoteNumber as 'SalesQuoteNumber', 
						--dbo.GenearteVersionNumber(SO.Version) as 'VersionNumber'
						SOQ.VersionNumber
						,SO.OpenDate, SOQ.OpenDate AS 'QuoteDate', C.CustomerId, C.Name, SO.CustomerReference, C.CustomerCode, MST.Name as 'Status',
						B.Cost,B.NetSales as 'SalesPrice',(E.FirstName+' '+E.LastName)as SalesPerson,CT.CustomerTypeName,
						SO.ShippedDate,
						A.SoAmount, SO.CreatedDate, SO.UpdatedDate, SO.StatusId, SO.CreatedBy, SO.UpdatedBy
						from dbo.SalesOrder SO WITH (NOLOCK) Inner Join MasterSalesOrderQuoteStatus MST on SO.StatusId = MST.Id
						Inner Join Customer C WITH (NOLOCK) on SO.CustomerId = C.CustomerId
						Inner Join CustomerType CT WITH (NOLOCK) on SO.AccountTypeId = CT.CustomerTypeId
						Left Join Employee E WITH (NOLOCK) on  E.EmployeeId = SO.SalesPersonId 
						Left Join SalesOrderQuote SOQ WITH (NOLOCK) on SOQ.SalesOrderQuoteId = SO.SalesOrderQuoteId and SOQ.SalesOrderQuoteId is not Null
						Outer Apply(
							Select SUM(NetSales) as SoAmount from SalesOrderPart WITH (NOLOCK) 
							Where SalesOrderId = SO.SalesOrderId
						) A
						Outer Apply (
							Select SUM(S.UnitCost) as 'Cost', SUM(S.NetSales) as 'NetSales' from SalesOrderPart S WITH (NOLOCK)
							Where S.SalesOrderId = SO.SalesOrderId
						) B
						Where (SO.IsDeleted = @IsDeleted) and (@StatusID is null or SO.StatusId = @StatusID) AND SO.MasterCompanyId = @MasterCompanyId),
						DatesCTE AS(
							Select SO.SalesOrderId, 
							A.RequestedDate,
							(Case When Count(SP.SalesOrderId) > 1 Then 'Multiple' ELse A.RequestedDate End)  as 'RequestedDateType',
							A.PromisedDate,
							A.EstimatedShipDate,
							(Case When Count(SP.SalesOrderId) > 1 Then 'Multiple' ELse A.EstimatedShipDate End)  as 'EstimatedShipDateType'
							from SalesOrder SO WITH (NOLOCK)
							Left Join SalesOrderPart SP WITH (NOLOCK) On SO.SalesOrderId = SP.SalesOrderId
							Outer Apply(
								SELECT 
								   STUFF((SELECT ',' + CONVERT(VARCHAR, CustomerRequestDate, 101)--CAST(CustomerRequestDate as varchar)
										  FROM SalesOrderPart S WITH (NOLOCK) Where S.SalesOrderId = SO.SalesOrderId
										  AND S.IsActive = 1 AND S.IsDeleted = 0
										  FOR XML PATH('')), 1, 1, '') RequestedDate,
								   STUFF((SELECT ',' + CONVERT(VARCHAR, PromisedDate, 101)--CAST(PromisedDate as varchar)
										  FROM SalesOrderPart S WITH (NOLOCK) Where S.SalesOrderId = SO.SalesOrderId
										  AND S.IsActive = 1 AND S.IsDeleted = 0
										  FOR XML PATH('')), 1, 1, '') PromisedDate,
								   STUFF((SELECT ',' + CONVERT(VARCHAR, EstimatedShipDate, 101)--CAST(EstimatedShipDate as varchar)
										  FROM SalesOrderPart S WITH (NOLOCK) Where S.SalesOrderId = SO.SalesOrderId
										  AND S.IsActive = 1 AND S.IsDeleted = 0
										  FOR XML PATH('')), 1, 1, '') EstimatedShipDate
							) A
							Where ((SO.IsDeleted = @IsDeleted) and (@StatusID is null or so.StatusId = @StatusID))
							AND SP.IsActive = 1 AND SP.IsDeleted = 0
							Group By SO.SalesOrderId, A.RequestedDate, A.PromisedDate, A.EstimatedShipDate
						),
						PartCTE AS(
						Select SO.SalesOrderId,(Case When Count(SP.SalesOrderId) > 1 Then 'Multiple' ELse A.PartNumber End)  as 'PartNumberType',A.PartNumber from SalesOrder SO WITH (NOLOCK)
						Left Join SalesOrderPart SP WITH (NOLOCK) On SO.SalesOrderId = SP.SalesOrderId
						Outer Apply(
							SELECT 
							   STUFF((SELECT ',' + I.partnumber
									  FROM SalesOrderPart S WITH (NOLOCK)
									  Left Join ItemMaster I WITH (NOLOCK) On S.ItemMasterId=I.ItemMasterId
									  Where S.SalesOrderId = SO.SalesOrderId
									  AND S.IsActive = 1 AND S.IsDeleted = 0
									  FOR XML PATH('')), 1, 1, '') PartNumber
						) A
						Where ((SO.IsDeleted = @IsDeleted) and (@StatusID is null or so.StatusId = @StatusID))
						AND SP.IsActive = 1 AND SP.IsDeleted = 0
						Group By SO.SalesOrderId, A.PartNumber
						),
						PartDescCTE AS(
						Select SO.SalesOrderId, (Case When Count(SP.SalesOrderId) > 1 Then 'Multiple' ELse A.PartDescription End)  as 'PartDescriptionType', A.PartDescription from SalesOrder SO WITH (NOLOCK)
						Left Join SalesOrderPart SP WITH (NOLOCK) On SO.SalesOrderId = SP.SalesOrderId
						Outer Apply(
							SELECT 
							   STUFF((SELECT ', ' + I.PartDescription
									  FROM SalesOrderPart S WITH (NOLOCK)
									  Left Join ItemMaster I WITH (NOLOCK) On S.ItemMasterId=I.ItemMasterId
									  Where S.SalesOrderId = SO.SalesOrderId
									  AND S.IsActive = 1 AND S.IsDeleted = 0
									  FOR XML PATH('')), 1, 1, '') PartDescription
						) A
						Where ((SO.IsDeleted = @IsDeleted) and (@StatusID is null or SO.StatusId = @StatusID))
						AND SP.IsActive = 1 AND SP.IsDeleted = 0
						Group By SO.SalesOrderId,A.PartDescription
						),PriorityCTE AS(
						Select SO.SalesOrderId,(Case When Count(SP.SalesOrderId) > 1 Then 'Multiple' ELse A.PriorityDescription End)  as 'PriorityType',A.PriorityDescription from SalesOrder SO WITH (NOLOCK)
						Left Join SalesOrderPart SP WITH (NOLOCK) On SO.SalesOrderId = SP.SalesOrderId
						Outer Apply(
							SELECT 
							   STUFF((SELECT ', ' + P.Description
									  FROM SalesOrderPart S WITH (NOLOCK)
									  Left Join Priority P WITH (NOLOCK) On P.PriorityId = S.PriorityId
									  Where S.SalesOrderId = SO.SalesOrderId
									  AND S.IsActive = 1 AND S.IsDeleted = 0
									  FOR XML PATH('')), 1, 1, '') PriorityDescription
						) A
						Where ((SO.IsDeleted = @IsDeleted) and (@StatusID is null or SO.StatusId = @StatusID))
						AND SP.IsActive = 1 AND SP.IsDeleted = 0
						Group By SO.SalesOrderId, A.PriorityDescription
						),Result AS(
						Select M.SalesOrderId, SalesOrderNumber,M.SalesQuoteNumber as 'SalesOrderQuoteNumber', M.QuoteDate as 'QuoteDate', M.OpenDate as 'OpenDate',M.CustomerId,M.Name as 'CustomerName',M.Status,
									M.VersionNumber,IsNull(M.SalesPrice,0) as 'QuoteAmount', IsNull(M.Cost,0) AS 'Cost', M.StatusId, M.CustomerReference,
									PR.PriorityDescription as 'Priority', PR.PriorityType, M.SalesPerson, PT.PartNumber, PT.PartNumberType, PD.PartDescription,
									PD.PartDescriptionType,M.CustomerTypeName as 'CustomerType',IsNULL(M.SoAmount,0) as 'SoAmount',
									D.RequestedDate, D.RequestedDateType, D.PromisedDate, D.EstimatedShipDate, D.EstimatedShipDateType,ShippedDate,
									M.CreatedDate,M.UpdatedDate,M.CreatedBy,M.UpdatedBy
									from Main M 
						Left Join PartCTE PT On M.SalesOrderId = PT.SalesOrderId
						Left Join PartDescCTE PD on PD.SalesOrderId = M.SalesOrderId
						Left Join PriorityCTE PR on PR.SalesOrderId = M.SalesOrderId
						LEFT JOIN DatesCTE D ON D.SalesOrderId = M.SalesOrderId
						Where (
						(@GlobalFilter <>'' AND ((M.SalesQuoteNumber like '%' +@GlobalFilter+'%' ) OR (M.SalesOrderNumber like '%' +@GlobalFilter+'%') OR
								(M.SalesOrderNumber like '%' +@GlobalFilter+'%') OR
								(M.Name like '%' +@GlobalFilter+'%') OR
								(M.Status like '%' +@GlobalFilter+'%') OR
								(M.VersionNumber like '%' +@GlobalFilter+'%') OR
								(M.SalesPerson like '%' +@GlobalFilter+'%') OR
								(PR.PriorityType like '%' +@GlobalFilter+'%') OR
								(PT.PartNumberType like '%' +@GlobalFilter+'%') OR
								(PD.PartDescriptionType like '%' +@GlobalFilter+'%') OR
								(M.CustomerReference like '%' +@GlobalFilter+'%') OR
								(M.CustomerTypeName like '%' +@GlobalFilter+'%') OR 
								(M.CreatedBy like '%' +@GlobalFilter+'%') OR
								(M.UpdatedBy like '%' +@GlobalFilter+'%') OR
								(OpenDate like '%' +@GlobalFilter+'%') OR
								(M.ShippedDate like '%' +@GlobalFilter+'%') OR
								(D.RequestedDateType like '%' +@GlobalFilter+'%') OR
								(D.EstimatedShipDateType like '%' +@GlobalFilter+'%')
								))
								OR   
								(@GlobalFilter='' AND (IsNull(@SOQNumber,'') ='' OR M.SalesQuoteNumber like '%'+@SOQNumber+'%') and 
								(IsNull(@SalesOrderNumber,'') ='' OR M.SalesOrderNumber like '%'+@SalesOrderNumber+'%') and
								(IsNull(@CustomerName,'') ='' OR M.Name like '%'+ @CustomerName+'%') and
								(@QuoteAmount is  null or M.SalesPrice=@QuoteAmount) and
								(@SoAmount is  null or M.SoAmount=@SoAmount) and
								(@QuoteDate is  null or Cast(M.OpenDate as date)=Cast(@QuoteDate as date)) and
								(IsNull(@SalesPerson,'') ='' OR M.SalesPerson like '%'+@SalesPerson+'%') and
								(IsNull(@PriorityType,'') ='' OR PR.PriorityType like '%'+ @PriorityType+'%') and
								(IsNull(@PartNumberType,'') ='' OR PT.PartNumberType like '%'+@PartNumberType+'%') and
								(IsNull(@PartDescriptionType,'') ='' OR PD.PartDescriptionType like '%'+@PartDescriptionType+'%') and
								(IsNull(@CustomerReference,'') ='' OR M.CustomerReference like '%'+@CustomerReference+'%') and
								(IsNull(@CustomerType,'') ='' OR M.CustomerTypeName like '%'+@CustomerType+'%') and
								(IsNull(@VersionNumber,'') ='' OR M.VersionNumber like '%'+@VersionNumber+'%') and
								(IsNull(@CreatedBy,'') ='' OR M.CreatedBy like '%'+@CreatedBy+'%') and
								(IsNull(@UpdatedBy,'') ='' OR M.UpdatedBy like '%'+@UpdatedBy+'%') and
								(IsNull(@CreatedDate,'') ='' OR Cast(M.CreatedDate as Date)=Cast(@CreatedDate as date)) and
								(IsNull(@UpdatedDate,'') ='' OR Cast(M.UpdatedDate as date)=Cast(@UpdatedDate as date)) and
								(IsNull(@OpenDate,'') ='' OR Cast(OpenDate as Date) = Cast(@OpenDate as date)) and
								(IsNull(@ShippedDate,'') ='' OR Cast(M.ShippedDate as Date) = Cast(@ShippedDate as date)) and
								(IsNull(@RequestedDateType,'') ='' OR D.RequestedDateType like '%'+@RequestedDateType+'%') and
								(IsNull(@EstimatedShipDateType,'') ='' OR D.EstimatedShipDateType like '%'+@EstimatedShipDateType+'%') )
								)
						), CTE_Count AS (Select COUNT(SalesOrderId) AS NumberOfItems FROM Result)
						SELECT SalesOrderId, SalesOrderNumber, SalesOrderQuoteNumber, VersionNumber, QuoteDate, OpenDate, CustomerId, CustomerName, CustomerReference,
						Priority,PriorityType, QuoteAmount, Cost, RequestedDate, RequestedDateType, EstimatedShipDate, EstimatedShipDateType, PromisedDate,
						ShippedDate, SalesPerson, Status, StatusId
						,PartNumber,PartNumberType,PartDescription,PartDescriptionType,
						CreatedDate, UpdatedDate, NumberOfItems, CreatedBy, UpdatedBy FROM Result,CTE_Count
						ORDER BY  
						CASE WHEN (@SortOrder=1 and @SortColumn='SALESORDERID')  THEN SalesOrderId END DESC,
						CASE WHEN (@SortOrder=1 and @SortColumn='CREATEDDATE')  THEN CreatedDate END ASC,
						CASE WHEN (@SortOrder=1 and @SortColumn='SALESQUOTENUMBER')  THEN SalesOrderQuoteNumber END ASC,
						CASE WHEN (@SortOrder=1 and @SortColumn='VERSIONNUMBER')  THEN VersionNumber END ASC,
						CASE WHEN (@SortOrder=1 and @SortColumn='OPENDATE')  THEN OpenDate END ASC,
						CASE WHEN (@SortOrder=1 and @SortColumn='QUOTEDATE')  THEN OpenDate END ASC,
						CASE WHEN (@SortOrder=1 and @SortColumn='STATUS')  THEN Status END ASC,
						CASE WHEN (@SortOrder=1 and @SortColumn='SALESORDERNUMBER')  THEN SalesOrderNumber END ASC,
						CASE WHEN (@SortOrder=1 and @SortColumn='PARTNUMBERTYPE')  THEN PartNumberType END ASC,
						CASE WHEN (@SortOrder=1 and @SortColumn='PARTDESCRIPTIONTYPE')  THEN PartDescriptionType END ASC,
						CASE WHEN (@SortOrder=1 and @SortColumn='CUSTOMERNAME')  THEN CustomerName END ASC,
						CASE WHEN (@SortOrder=1 and @SortColumn='CUSTOMERTYPE')  THEN CustomerType END ASC,
						CASE WHEN (@SortOrder=1 and @SortColumn='CUSTOMERREFERENCE')  THEN CustomerReference END ASC,
						CASE WHEN (@SortOrder=1 and @SortColumn='QUOTEAMOUNT')  THEN QuoteAmount END ASC,
						CASE WHEN (@SortOrder=1 and @SortColumn='SOAMOUNT')  THEN SoAmount END ASC,
						CASE WHEN (@SortOrder=1 and @SortColumn='PRIORITYTYPE')  THEN PriorityType END ASC,
						CASE WHEN (@SortOrder=1 and @SortColumn='SALESPERSON')  THEN SalesPerson END ASC,
						CASE WHEN (@SortOrder=1 and @SortColumn='UPDATEDDATE')  THEN UpdatedDate END ASC,
						CASE WHEN (@SortOrder=1 and @SortColumn='CREATEDBY')  THEN CreatedBy END ASC,
						CASE WHEN (@SortOrder=1 and @SortColumn='UPDATEDBY')  THEN UpdatedBy END ASC,
						CASE WHEN (@SortOrder=-1 and @SortColumn='CREATEDDATE')  THEN CreatedDate END Desc,
						CASE WHEN (@SortOrder=-1 and @SortColumn='SALESQUOTENUMBER')  THEN SalesOrderQuoteNumber END Desc,
						CASE WHEN (@SortOrder=-1 and @SortColumn='VERSIONNUMBER')  THEN VersionNumber END Desc,
						CASE WHEN (@SortOrder=-1 and @SortColumn='OPENDATE')  THEN OpenDate END Desc,
						CASE WHEN (@SortOrder=-1 and @SortColumn='QUOTEDATE')  THEN OpenDate END Desc,
						CASE WHEN (@SortOrder=-1 and @SortColumn='STATUS')  THEN Status END Desc,
						CASE WHEN (@SortOrder=-1 and @SortColumn='SALESORDERNUMBER')  THEN SalesOrderNumber END Desc,
						CASE WHEN (@SortOrder=-1 and @SortColumn='PARTNUMBERTYPE')  THEN PartNumberType END Desc,
						CASE WHEN (@SortOrder=-1 and @SortColumn='PARTDESCRIPTIONTYPE')  THEN PartDescriptionType END Desc,
						CASE WHEN (@SortOrder=-1 and @SortColumn='CUSTOMERNAME')  THEN CustomerName END Desc,
						CASE WHEN (@SortOrder=-1 and @SortColumn='CUSTOMERTYPE')  THEN CustomerType END Desc,
						CASE WHEN (@SortOrder=-1 and @SortColumn='CUSTOMERREFERENCE')  THEN CustomerReference END Desc,
						CASE WHEN (@SortOrder=-1 and @SortColumn='QUOTEAMOUNT')  THEN QuoteAmount END Desc,
						CASE WHEN (@SortOrder=-1 and @SortColumn='SOAMOUNT')  THEN SoAmount END Desc,
						CASE WHEN (@SortOrder=-1 and @SortColumn='PRIORITYTYPE')  THEN PriorityType END Desc,
						CASE WHEN (@SortOrder=-1 and @SortColumn='SALESPERSON')  THEN SalesPerson END Desc,
						CASE WHEN (@SortOrder=-1 and @SortColumn='UPDATEDDATE')  THEN UpdatedDate END Desc,
						CASE WHEN (@SortOrder=-1 and @SortColumn='CREATEDBY')  THEN CreatedBy END DESC,
						CASE WHEN (@SortOrder=-1 and @SortColumn='UPDATEDBY')  THEN UpdatedBy END DESC
						OFFSET @RecordFrom ROWS 
						FETCH NEXT @PageSize ROWS ONLY
					END
			COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'SearchSOViewData' 
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
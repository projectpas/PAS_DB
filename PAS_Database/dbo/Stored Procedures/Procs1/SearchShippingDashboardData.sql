-------------------------------------------------------------------------------------------

-- EXEC [dbo].[SearchPORODashboardData] 1, 10, null, 1, 1
CREATE   PROCEDURE [dbo].[SearchShippingDashboardData]
	@PageNumber int,
	@PageSize int,
	@SortColumn varchar(50) = null,
	@SortOrder int,
	@StatusID int,
	@GlobalFilter varchar(50) = null,
	@Module varchar(50) = null,
	@RefId bigint = null,
	@Reference varchar(50) = null,
	@Customer varchar(50) = null,
	@PartNumber varchar(50) = null,
	@PartDescription varchar(100) = null,
	@PromisedDate datetime = null,
	@Priority varchar(50) = null,
	@Carrier varchar(50) = null,
	@ShippingMethod varchar(50) = null,
	@Status varchar(50) = null,
	@timeHrs datetime = null,
	@RefNumber varchar(50) = null,
    @IsDeleted bit = null,
	@MasterCompanyId int = null,
	@EmployeeId bigint = 1
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
				DECLARE @POModuleId int =5;
				DECLARE @ROModuleId int =25;
				SET @RecordFrom = (@PageNumber-1) * @PageSize;
				
				IF @SortColumn IS NULL
				BEGIN
					SET @SortColumn = Upper('Customer')
				END 
				ELSE
				BEGIN 
					SET @SortColumn = Upper(@SortColumn)
				END
		
				IF @StatusID = 0
				BEGIN 
					SET @StatusID = null
				END 

				IF @Status = '0'
				BEGIN
					SET @Status = null
				END

				;With Result AS(
				SELECT  wop.WorkOrderId as RefId,
						wop.id as RefPartId,
						wo.WorkOrderNum as RefNumber,
						wopt.PickTicketId as PickTicketId,
						Max(wo.CustomerName) as Customer,
						wo.CustomerId as CustomerId,
						'WO' AS 'Module',
						imt.partnumber,
						imt.PartDescription,
						Max(wop.PromisedDate) as PromisedDate,
						Max(P.Description) as Priority,
						Max(SV.ShipVia) as Carrier,
						'' as ShippingMethod,
						'Ready to ship' as'Status',
						Max(wopt.ConfirmedDate) as timeHrs
					    FROM DBO.WOPickTicket wopt WITH (NOLOCK) 
						INNER JOIN DBO.WorkOrderPartNumber wop WITH (NOLOCK)  ON wopt.WorkorderId = wop.WorkorderId  AND wopt.OrderPartId = wop.ID
						INNER JOIN DBO.WorkOrder wo WITH (NOLOCK)  ON wo.WorkOrderId = wop.WorkOrderId
						LEFT JOIN DBO.ItemMaster imt  WITH (NOLOCK) on imt.ItemMasterId = wop.ItemMasterId
						LEFT JOIN DBO.Priority P WITH (NOLOCK)  ON P.PriorityId = wop.WorkOrderPriorityId
						LEFT JOIN DBO.CustomerDomensticShippingShipVia SV WITH (NOLOCK)  ON SV.CustomerId = wo.CustomerId and sv.IsPrimary=1
				        WHERE wopt.IsDeleted = 0 and wopt.MasterCompanyId= @MasterCompanyId and wo.IsDeleted = 0  and wopt.IsConfirmed=1 
						and wop.ID not in(SELECT WorkOrderPartNumId FROM DBO.WorkOrderShippingItem WOBI 
										WHERE WOBI.IsDeleted = 0) 
						GROUP BY wopt.PickTicketId,wo.CustomerId,wo.WorkOrderNum,imt.partnumber,imt.PartDescription,wop.WorkOrderId,wop.ID
				UNION
				SELECT  sop.SalesOrderId as RefId,
						sop.SalesOrderPartId as RefPartId,
						so.SalesOrderNumber as RefNumber,
						sopt.SOPickTicketId as PickTicketId,
						Max(so.CustomerName) as Customer,
						so.CustomerId as CustomerId,
						'SO' AS 'Module',
						imt.partnumber,
						imt.PartDescription,
						Max(sop.PromisedDate) as PromisedDate ,
						Max(P.Description) as Priority,
						Max(SV.ShipVia) as Carrier,
						'' as ShippingMethod,
						'Ready to ship' as'Status',
						Max(sopt.ConfirmedDate) as timeHrs
				        FROM DBO.SalesOrderPart sop WITH (NOLOCK)
						LEFT JOIN DBO.SalesOrder so WITH (NOLOCK) ON so.SalesOrderId = sop.SalesOrderId
						INNER JOIN DBO.SOPickTicket sopt WITH (NOLOCK) ON sopt.SalesOrderId = sop.SalesOrderId AND sopt.SalesOrderPartId = sop.SalesOrderPartId
						LEFT JOIN DBO.ItemMaster imt WITH (NOLOCK) ON imt.ItemMasterId = sop.ItemMasterId
						LEFT JOIN DBO.Priority P WITH (NOLOCK)  ON P.PriorityId = sop.PriorityId
						LEFT JOIN DBO.CustomerDomensticShippingShipVia SV WITH (NOLOCK)  ON SV.CustomerId = so.CustomerId and sv.IsPrimary=1
						WHERE  sopt.IsDeleted = 0 and sopt.MasterCompanyId= @MasterCompanyId AND sopt.IsConfirmed = 1
						and sop.SalesOrderPartId not in(SELECT SalesOrderPartId FROM DBO.SalesOrderShippingItem WOBI 
										WHERE WOBI.IsDeleted = 0) 
						
						GROUP BY sopt.SOPickTicketId,so.CustomerId,so.SalesOrderNumber,sop.SalesOrderPartId,imt.partnumber, imt.PartDescription, imt.ItemMasterId, sop.SalesOrderId, sop.ConditionId

						UNION

						SELECT  sop.ExchangeSalesOrderId as RefId,
						sop.ExchangeSalesOrderPartId as RefPartId,
						so.ExchangeSalesOrderNumber as RefNumber,
						sopt.SOPickTicketId as PickTicketId,
						Max(so.CustomerName) as Customer,
						so.CustomerId as CustomerId,
						'ESO' AS 'Module',
						imt.partnumber,
						imt.PartDescription,
						Max(sop.PromisedDate) as PromisedDate,
						Max(P.Description) as Priority,
						Max(SV.ShipVia) as Carrier,
						'' as ShippingMethod,
						'Ready to ship' as'Status',
						Max(sopt.ConfirmedDate) as timeHrs
						
					from DBO.ExchangeSalesOrderPart sop WITH (NOLOCK)
						LEFT JOIN DBO.ExchangeSalesOrder so WITH (NOLOCK) on so.ExchangeSalesOrderId = sop.ExchangeSalesOrderId
						INNER JOIN DBO.ExchangeSOPickTicket sopt WITH (NOLOCK) on sopt.ExchangeSalesOrderId = sop.ExchangeSalesOrderId AND sopt.ExchangeSalesOrderPartId = sop.ExchangeSalesOrderPartId
						LEFT JOIN DBO.ItemMaster imt WITH (NOLOCK) on imt.ItemMasterId = sop.ItemMasterId
						LEFT JOIN DBO.Stockline sl WITH (NOLOCK) on sl.StockLineId = sop.StockLineId
						LEFT JOIN DBO.Priority P WITH (NOLOCK)  ON P.PriorityId = sop.PriorityId
						LEFT JOIN DBO.CustomerDomensticShippingShipVia SV WITH (NOLOCK)  ON SV.CustomerId = so.CustomerId and sv.IsPrimary=1
						WHERE  sopt.IsDeleted = 0 and sopt.MasterCompanyId= @MasterCompanyId  and so.IsDeleted = 0  and sopt.IsConfirmed = 1
						and sop.ExchangeSalesOrderPartId not in(SELECT ExchangeSalesOrderPartId FROM DBO.ExchangeSalesOrderShippingItem WOBI 
										WHERE WOBI.IsDeleted = 0) 
						GROUP BY sopt.SOPickTicketId,so.CustomerId,sop.ExchangeSalesOrderPartId,so.ExchangeSalesOrderNumber,imt.partnumber,imt.PartDescription, imt.ItemMasterId,
		                sop.ExchangeSalesOrderId--,sop.SalesOrderPartId--, sop.ItemNo;
				
				),
				FinalResult AS (
				SELECT Module, RefId, RefPartId, RefNumber,PickTicketId,Customer,CustomerId, PartNumber, PartDescription, Carrier, ShippingMethod, 
				timeHrs, PromisedDate, Status,Priority FROM Result
				where (
					(@GlobalFilter <> '' AND ((Module like '%' + @GlobalFilter +'%' ) OR 
							(RefNumber like '%' + @GlobalFilter +'%') OR
							(Customer like '%' + @GlobalFilter +'%') OR
							(PartNumber like '%' + @GlobalFilter +'%') OR
							(PartDescription like '%'+ @GlobalFilter +'%') OR
							(Carrier like '%' + @GlobalFilter +'%') OR
							(ShippingMethod like '%' + @GlobalFilter +'%') OR
							(Priority like '%' + @GlobalFilter +'%') OR
							(timeHrs  LIKE '%' +@GlobalFilter+'%') OR
							(PromisedDate like '%' + @GlobalFilter +'%') OR
							(Status like '%' + @GlobalFilter +'%')
							))
							OR   
							(@GlobalFilter = '' AND 
							(IsNull(@Module, '') = '' OR Module like  '%'+ @Module +'%') and 
							(IsNull(@RefNumber, '') = '' OR RefNumber like  '%'+ @RefNumber +'%') and
							(IsNull(@PartNumber, '') = '' OR PartNumber like '%'+ @PartNumber +'%') and
							(IsNull(@PartDescription, '') = '' OR PartDescription like '%'+ @PartDescription +'%') and
							(IsNull(@Customer, '') = '' OR Customer like '%'+ @Customer +'%') and
							(IsNull(@Carrier, '') = '' OR Carrier like '%'+ @Carrier +'%') and
							--(ISNULL(@timeHrs,0) =0 OR timeHrs =@timeHrs) AND
							(IsNull(@ShippingMethod, '') = '' OR ShippingMethod like '%'+ @ShippingMethod +'%') and
							(IsNull(@Priority, '') = '' OR Priority like '%'+ @Priority +'%') and
							(IsNull(@PromisedDate, '') = '' OR Cast(PromisedDate as Date) = Cast(@PromisedDate as date)) and
							(IsNull(@timeHrs, '') = '' OR Cast(timeHrs as Date) = Cast(@timeHrs as date)) and
							(IsNull(@Status,'') ='' OR Status like  '%'+@Status+'%'))
							)),
					ResultCount AS (Select COUNT(RefId) AS NumberOfItems FROM FinalResult)

					SELECT Module, RefId, RefPartId, RefNumber,PickTicketId, Customer,CustomerId,PartNumber, PartDescription, Carrier, ShippingMethod, 
				timeHrs, PromisedDate, Status,Priority, NumberOfItems FROM FinalResult, ResultCount
				ORDER BY  
				CASE WHEN (@SortOrder=1 and @SortColumn='MODULE')  THEN Module END ASC,
				CASE WHEN (@SortOrder=1 and @SortColumn='REFID')  THEN RefId END ASC,
				CASE WHEN (@SortOrder=1 and @SortColumn='RefNumber')  THEN RefNumber END ASC,
				CASE WHEN (@SortOrder=1 and @SortColumn='Customer')  THEN Customer END ASC,
				CASE WHEN (@SortOrder=1 and @SortColumn='PARTNUMBER')  THEN PartNumber END ASC,
				CASE WHEN (@SortOrder=1 and @SortColumn='PARTDESCRIPTION')  THEN PartDescription END ASC,
				CASE WHEN (@SortOrder=1 and @SortColumn='Carrier')  THEN Carrier END ASC,
				CASE WHEN (@SortOrder=1 and @SortColumn='ShippingMethod')  THEN ShippingMethod END ASC,
				CASE WHEN (@SortOrder=1 and @SortColumn='timeHrs')  THEN timeHrs END ASC,
				CASE WHEN (@SortOrder=1 and @SortColumn='PROMISEDDATE')  THEN PROMISEDDATE END ASC,
				CASE WHEN (@SortOrder=1 and @SortColumn='Status')  THEN Status END ASC,
				CASE WHEN (@SortOrder=1 and @SortColumn='PRIORITY')  THEN Priority END ASC,

				CASE WHEN (@SortOrder=-1 and @SortColumn='MODULE')  THEN Module END DESC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='REFID')  THEN RefId END DESC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='RefNumber')  THEN RefNumber END DESC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='Customer')  THEN Customer END DESC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='PARTNUMBER')  THEN PartNumber END DESC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='PARTDESCRIPTION')  THEN PartDescription END DESC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='Carrier')  THEN Carrier END DESC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='ShippingMethod')  THEN ShippingMethod END DESC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='timeHrs')  THEN timeHrs END DESC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='PROMISEDDATE')  THEN PromisedDate END DESC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='STATUS')  THEN Status END DESC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='PRIORITY')  THEN Priority END DESC

				OFFSET @RecordFrom ROWS 
				FETCH NEXT @PageSize ROWS ONLY
			END
		COMMIT  TRANSACTION

		END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			ROLLBACK TRAN;
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
        ,@AdhocComments VARCHAR(150) = 'SearchShippingDashboardData' 
        ,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = '''+ ISNULL(@PageNumber, '') + ''
        ,@ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
        exec spLogException 
                @DatabaseName         =  @DatabaseName
                ,@AdhocComments       =  @AdhocComments
                ,@ProcedureParameters =  @ProcedureParameters
                ,@ApplicationName     =  @ApplicationName
                ,@ErrorLogID          =  @ErrorLogID OUTPUT;
        RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
        RETURN(1);
	END CATCH
END
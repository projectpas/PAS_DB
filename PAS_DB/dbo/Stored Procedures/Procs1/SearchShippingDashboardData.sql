/*************************************************************           
 ** File:   [SearchShippingDashboardData]
 ** Author: unknown
 ** Description: 
 ** Purpose:         
 ** Date:          
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date          Author				Change Description            
 ** --   --------      -------				--------------------------------
	1    11/04/2024	   Vishal Suthar		Modified to make use of new SO Part tables
	2    04-15-2025	   Amit Ghediya			Added qtyShipped,qtyRemaining for shipping details
	3    14-May-2025   Divyesh Kathiriya	Added AWB Field. [PN-16424]
	4    03-Jun-2026   Sumit Kumar      Added RO and Vendor RMA shipping entries to dashboard
	5    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
	6    09/July/2026			 RAJESH GAMI						[PN-17009] - Merge Non-Stock Inventory to Stockline : Get only Stock Inventory Data Where IsNonStock = 0

-- EXEC [dbo].[SearchShippingDashboardData] @PageSize=10,@PageNumber=1,@SortColumn=NULL,@SortOrder=1,@StatusID=0,@GlobalFilter=N'',@Module=NULL,@RefId=0,
											@Reference=NULL,@Customer=NULL,@PartNumber=NULL,@PartDescription=NULL,@PromisedDate=NULL,@Priority=NULL,@Carrier=NULL,@ShippingMethod=NULL,
											@Status=NULL,@timeHrs=NULL,@RefNumber=NULL,@IsDeleted=0,@MasterCompanyId=1,@EmployeeId=212,@QtyShipped=NULL,@QtyRemaining=NULL,@AirwayBill=N''
************************************************************************/
CREATE    PROCEDURE [dbo].[SearchShippingDashboardData]
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
	@EmployeeId bigint = 1,
	@QtyShipped varchar(50) = NULL,
	@QtyRemaining varchar(50) = NULL,
	@AirwayBill varchar(50) = NULL
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
				
				--IF @SortColumn IS NULL
				--BEGIN
				--	SET @SortColumn = Upper('Customer')
				--END 
				--ELSE
				--BEGIN 
				--	SET @SortColumn = Upper(@SortColumn)
				--END
		
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
						--'Ready to ship' as'Status',
						CASE WHEN ISNULL(WOSI.QtyShipped,0) > 0 THEN 'Shipped' ELSE 'Ready to ship' END as'Status',
						Max(wopt.ConfirmedDate) as timeHrs,
						ISNULL(WOSI.QtyShipped,0) AS QtyShipped,
						ISNULL(wop.Quantity,0) - ISNULL(WOSI.QtyShipped,0)  AS QtyRemaining,
						wo.CreatedDate AS CreatedDate,
						WOS.AirwayBill AS AirwayBill
					    FROM DBO.WOPickTicket wopt WITH (NOLOCK) 
						INNER JOIN DBO.WorkOrderPartNumber wop WITH (NOLOCK)  ON wopt.WorkorderId = wop.WorkorderId  AND wopt.OrderPartId = wop.ID
						INNER JOIN DBO.WorkOrder wo WITH (NOLOCK)  ON wo.WorkOrderId = wop.WorkOrderId
						LEFT JOIN DBO.ItemMaster imt  WITH (NOLOCK) on imt.ItemMasterId = wop.ItemMasterId
						 AND ISNULL(imt.IsNonStock,0) = 0
						 LEFT JOIN DBO.Priority P WITH (NOLOCK)  ON P.PriorityId = wop.WorkOrderPriorityId
						LEFT JOIN DBO.CustomerDomensticShippingShipVia SV WITH (NOLOCK)  ON SV.CustomerId = wo.CustomerId and sv.IsPrimary=1
						LEFT JOIN DBO.WorkOrderShippingItem WOSI WITH (NOLOCK)  ON WOSI.WorkOrderPartNumId = wopt.OrderPartId AND WOSI.WOPickTicketId = wopt.PickTicketId						
						LEFT JOIN DBO.WorkOrderShipping WOS WITH (NOLOCK) ON WOSI.WorkOrderShippingId = WOS.WorkOrderShippingId
				        WHERE wopt.IsDeleted = 0 and wopt.MasterCompanyId= @MasterCompanyId and wo.IsDeleted = 0  and wopt.IsConfirmed=1 
						--and wop.ID not in(SELECT WorkOrderPartNumId FROM DBO.WorkOrderShippingItem WOBI 
						--				WHERE WOBI.IsDeleted = 0) 
						GROUP BY wopt.PickTicketId,wo.CustomerId,wo.WorkOrderNum,imt.partnumber,
						imt.PartDescription,wop.WorkOrderId,wop.ID,WOSI.QtyShipped,wop.Quantity,wo.CreatedDate,WOS.AirwayBill
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
						--'Ready to ship' as'Status',
						CASE WHEN ISNULL(SOSI.QtyShipped,0) > 0 THEN 'Shipped' ELSE 'Ready to ship' END as'Status',
						Max(sopt.ConfirmedDate) as timeHrs,
						ISNULL(SOSI.QtyShipped,0) AS QtyShipped,
						ISNULL(sopt.QtyToShip,0) - ISNULL(SOSI.QtyShipped,0)  AS QtyRemaining,
						so.CreatedDate AS CreatedDate,
						SOS.AirwayBill AS AirwayBill
				        FROM DBO.SalesOrderPartV1 sop WITH (NOLOCK)
						LEFT JOIN DBO.SalesOrder so WITH (NOLOCK) ON so.SalesOrderId = sop.SalesOrderId
						INNER JOIN DBO.SOPickTicket sopt WITH (NOLOCK) ON sopt.SalesOrderId = sop.SalesOrderId AND sopt.SalesOrderPartId = sop.SalesOrderPartId
						LEFT JOIN DBO.ItemMaster imt WITH (NOLOCK) ON imt.ItemMasterId = sop.ItemMasterId
						 AND ISNULL(imt.IsNonStock,0) = 0
						 LEFT JOIN DBO.Priority P WITH (NOLOCK)  ON P.PriorityId = sop.PriorityId
						LEFT JOIN DBO.CustomerDomensticShippingShipVia SV WITH (NOLOCK)  ON SV.CustomerId = so.CustomerId and sv.IsPrimary=1
						LEFT JOIN DBO.SalesOrderShippingItem SOSI WITH (NOLOCK)  ON SOSI.SalesOrderPartId = sopt.SalesOrderPartId AND SOSI.SOPickTicketId = sopt.SOPickTicketId						
						LEFT JOIN DBO.SalesOrderShipping SOS WITH (NOLOCK)  ON SOSI.SalesOrderShippingId = SOS.SalesOrderShippingId
						WHERE  sopt.IsDeleted = 0 and sopt.MasterCompanyId= @MasterCompanyId AND sopt.IsConfirmed = 1
						--and sop.SalesOrderPartId not in(SELECT SalesOrderPartId FROM DBO.SalesOrderShippingItem WOBI 
						--				WHERE WOBI.IsDeleted = 0) 
						GROUP BY sopt.SOPickTicketId,so.CustomerId,so.SalesOrderNumber,sop.SalesOrderPartId,imt.partnumber, 
						imt.PartDescription, imt.ItemMasterId, sop.SalesOrderId, sop.ConditionId,SOSI.QtyShipped,sopt.QtyToShip,so.CreatedDate,SOS.AirwayBill

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
						--'Ready to ship' as'Status',
						CASE WHEN ISNULL(EOSI.QtyShipped,0) > 0 THEN 'Shipped' ELSE 'Ready to ship' END as'Status',
						Max(sopt.ConfirmedDate) as timeHrs,
						ISNULL(EOSI.QtyShipped,0) AS QtyShipped,
						ISNULL(sop.QtyRequested,0) - ISNULL(EOSI.QtyShipped,0)  AS QtyRemaining,
						so.CreatedDate AS CreatedDate,
						EOS.AirwayBill AS AirwayBill
					from DBO.ExchangeSalesOrderPart sop WITH (NOLOCK)
						LEFT JOIN DBO.ExchangeSalesOrder so WITH (NOLOCK) on so.ExchangeSalesOrderId = sop.ExchangeSalesOrderId
						INNER JOIN DBO.ExchangeSOPickTicket sopt WITH (NOLOCK) on sopt.ExchangeSalesOrderId = sop.ExchangeSalesOrderId AND sopt.ExchangeSalesOrderPartId = sop.ExchangeSalesOrderPartId
						LEFT JOIN DBO.ItemMaster imt WITH (NOLOCK) on imt.ItemMasterId = sop.ItemMasterId
						 AND ISNULL(imt.IsNonStock,0) = 0
						 LEFT JOIN DBO.Stockline sl WITH (NOLOCK) on sl.StockLineId = sop.StockLineId AND ISNULL(sl.IsNonStock,0) = 0
						LEFT JOIN DBO.Priority P WITH (NOLOCK)  ON P.PriorityId = sop.PriorityId
						LEFT JOIN DBO.CustomerDomensticShippingShipVia SV WITH (NOLOCK)  ON SV.CustomerId = so.CustomerId and sv.IsPrimary=1
						LEFT JOIN DBO.ExchangeSalesOrderShippingItem EOSI WITH (NOLOCK)  ON EOSI.ExchangeSalesOrderPartId = sopt.ExchangeSalesOrderPartId AND EOSI.SOPickTicketId = sopt.SOPickTicketId						
						LEFT JOIN DBO.ExchangeSalesOrderShipping EOS WITH (NOLOCK)  ON EOSI.ExchangeSalesOrderShippingId = EOS.ExchangeSalesOrderShippingId
						WHERE  sopt.IsDeleted = 0 and sopt.MasterCompanyId= @MasterCompanyId  and so.IsDeleted = 0  and sopt.IsConfirmed = 1
						--and sop.ExchangeSalesOrderPartId not in(SELECT ExchangeSalesOrderPartId FROM DBO.ExchangeSalesOrderShippingItem WOBI 
						--				WHERE WOBI.IsDeleted = 0) 
						GROUP BY sopt.SOPickTicketId,so.CustomerId,sop.ExchangeSalesOrderPartId,so.ExchangeSalesOrderNumber,imt.partnumber,imt.PartDescription, imt.ItemMasterId,
		                sop.ExchangeSalesOrderId,EOSI.QtyShipped,sop.QtyRequested,so.CreatedDate, EOS.AirwayBill --,sop.SalesOrderPartId--, sop.ItemNo;

						UNION

						SELECT  rop.RepairOrderId as RefId,
						rop.RepairOrderPartRecordId as RefPartId,
						ro.RepairOrderNumber as RefNumber,
						ropt.ROPickTicketId as PickTicketId,
						Max(ro.VendorName) as Customer,
						ro.VendorId as CustomerId,
						'RO' AS 'Module',
						imt.partnumber,
						imt.PartDescription,
						Max(rop.EstRecordDate) as PromisedDate,
						Max(ISNULL(P.Description, rop.Priority)) as Priority,
						Max(VS.ShipVia) as Carrier,
						'' as ShippingMethod,
						CASE WHEN ISNULL(ROSI.QtyShipped,0) > 0 THEN 'Shipped' ELSE 'Ready to ship' END as 'Status',
						Max(ropt.ConfirmedDate) as timeHrs,
						ISNULL(ROSI.QtyShipped,0) AS QtyShipped,
						ISNULL(ropt.QtyToShip,0) - ISNULL(ROSI.QtyShipped,0) AS QtyRemaining,
						ro.CreatedDate AS CreatedDate,
						ROS.AirwayBill AS AirwayBill
				        FROM DBO.ROPickTicket ropt WITH (NOLOCK)
						INNER JOIN DBO.RepairOrderPart rop WITH (NOLOCK) ON ropt.RepairOrderId = rop.RepairOrderId AND ropt.RepairOrderPartId = rop.RepairOrderPartRecordId AND ropt.StocklineId = rop.StockLineId
						INNER JOIN DBO.RepairOrder ro WITH (NOLOCK) ON ro.RepairOrderId = rop.RepairOrderId
						LEFT JOIN DBO.ItemMaster imt WITH (NOLOCK) on imt.ItemMasterId = rop.ItemMasterId
						 AND ISNULL(imt.IsNonStock,0) = 0
						 LEFT JOIN DBO.Priority P WITH (NOLOCK) ON P.PriorityId = rop.PriorityId
						LEFT JOIN DBO.VendorShipping VS WITH (NOLOCK) ON VS.VendorId = ro.VendorId and VS.IsPrimary=1
						LEFT JOIN DBO.RepairOrderShippingItem ROSI WITH (NOLOCK) ON ROSI.RepairOrderPartId = ropt.RepairOrderPartId AND ROSI.ROPickTicketId = ropt.ROPickTicketId
						LEFT JOIN DBO.RepairOrderShipping ROS WITH (NOLOCK) ON ROSI.RepairOrderShippingId = ROS.RepairOrderShippingId
				        WHERE ropt.IsDeleted = 0 and ropt.MasterCompanyId= @MasterCompanyId and ro.IsDeleted = 0 and ropt.IsConfirmed=1
						GROUP BY ropt.ROPickTicketId,ro.VendorId,ro.RepairOrderNumber,rop.RepairOrderPartRecordId,imt.partnumber,
						imt.PartDescription,rop.RepairOrderId,ROSI.QtyShipped,ropt.QtyToShip,ro.CreatedDate,ROS.AirwayBill

						UNION

						SELECT  rma.VendorRMAId as RefId,
						rmad.VendorRMADetailId as RefPartId,
						rma.RMANumber as RefNumber,
						rmpt.RMAPickTicketId as PickTicketId,
						Max(V.VendorName) as Customer,
						rma.VendorId as CustomerId,
						'VRMA' AS 'Module',
						imt.partnumber,
						imt.PartDescription,
						Max(rma.OpenDate) as PromisedDate,
						'' as Priority,
						Max(VS.ShipVia) as Carrier,
						'' as ShippingMethod,
						CASE WHEN ISNULL(RMSI.QtyShipped,0) > 0 THEN 'Shipped' ELSE 'Ready to ship' END as 'Status',
						Max(rmpt.ConfirmedDate) as timeHrs,
						ISNULL(RMSI.QtyShipped,0) AS QtyShipped,
						ISNULL(rmpt.QtyToShip,0) - ISNULL(RMSI.QtyShipped,0) AS QtyRemaining,
						rma.CreatedDate AS CreatedDate,
						RMS.AirwayBill AS AirwayBill
				        FROM DBO.RMAPickTicket rmpt WITH (NOLOCK)
						INNER JOIN DBO.VendorRMADetail rmad WITH (NOLOCK) ON rmpt.VendorRMAId = rmad.VendorRMAId AND rmpt.VendorRMADetailId = rmad.VendorRMADetailId
						INNER JOIN DBO.VendorRMA rma WITH (NOLOCK) ON rma.VendorRMAId = rmad.VendorRMAId
						INNER JOIN DBO.Vendor V WITH (NOLOCK) ON V.VendorId = rma.VendorId
						LEFT JOIN DBO.ItemMaster imt WITH (NOLOCK) ON imt.ItemMasterId = rmad.ItemMasterId
						 AND ISNULL(imt.IsNonStock,0) = 0
						 LEFT JOIN DBO.VendorShipping VS WITH (NOLOCK) ON VS.VendorId = rma.VendorId and VS.IsPrimary=1
						LEFT JOIN DBO.RMAShippingItem RMSI WITH (NOLOCK) ON RMSI.VendorRMADetailId = rmpt.VendorRMADetailId AND RMSI.RMAPickTicketId = rmpt.RMAPickTicketId
						LEFT JOIN DBO.RMAShipping RMS WITH (NOLOCK) ON RMSI.RMAShippingId = RMS.RMAShippingId
				        WHERE rmpt.IsDeleted = 0 and rmpt.MasterCompanyId= @MasterCompanyId and rma.IsDeleted = 0 and rmpt.IsConfirmed=1
						GROUP BY rmpt.RMAPickTicketId,rma.VendorId,rma.RMANumber,rmad.VendorRMADetailId,imt.partnumber,
						imt.PartDescription,rma.VendorRMAId,RMSI.QtyShipped,rmpt.QtyToShip,rma.CreatedDate,RMS.AirwayBill
				),
				FinalResult AS (
				SELECT Module, RefId, RefPartId, RefNumber,PickTicketId,Customer,CustomerId, PartNumber, PartDescription, Carrier, ShippingMethod, 
				timeHrs,QtyShipped,QtyRemaining,CreatedDate, PromisedDate, Status,Priority, AirwayBill FROM Result
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
							(QtyShipped  LIKE '%' +@GlobalFilter+'%') OR
							(QtyRemaining  LIKE '%' +@GlobalFilter+'%') OR
							(PromisedDate like '%' + @GlobalFilter +'%') OR
							(Status like '%' + @GlobalFilter +'%') OR
							(AirwayBill like '%' + @GlobalFilter +'%')
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
							(ISNULL(@QtyShipped,'') ='' OR QtyShipped like '%'+@QtyShipped+'%') AND
							(ISNULL(@QtyRemaining,'') ='' OR QtyRemaining like '%'+@QtyRemaining+'%') AND
							(IsNull(@Status,'') ='' OR Status like  '%'+@Status+'%') AND
							(IsNull(@AirwayBill,'') ='' OR AirwayBill like  '%'+@AirwayBill+'%')
							))),
					ResultCount AS (Select COUNT(RefId) AS NumberOfItems FROM FinalResult)

					SELECT Module, RefId, RefPartId, RefNumber,PickTicketId, Customer,CustomerId,PartNumber, PartDescription, Carrier, ShippingMethod, 
				timeHrs,QtyShipped,QtyRemaining, PromisedDate, Status,Priority, AirwayBill, NumberOfItems FROM FinalResult, ResultCount
				ORDER BY  
				CASE WHEN (@SortOrder=1 and ISNULL(@SortColumn, '') = '') THEN CreatedDate END DESC,
				CASE WHEN (@SortOrder=1 and @SortColumn='MODULE')  THEN Module END ASC,
				CASE WHEN (@SortOrder=1 and @SortColumn='REFID')  THEN RefId END ASC,
				CASE WHEN (@SortOrder=1 and @SortColumn='RefNumber')  THEN RefNumber END ASC,
				CASE WHEN (@SortOrder=1 and @SortColumn='Customer')  THEN Customer END ASC,
				CASE WHEN (@SortOrder=1 and @SortColumn='PARTNUMBER')  THEN PartNumber END ASC,
				CASE WHEN (@SortOrder=1 and @SortColumn='PARTDESCRIPTION')  THEN PartDescription END ASC,
				CASE WHEN (@SortOrder=1 and @SortColumn='Carrier')  THEN Carrier END ASC,
				CASE WHEN (@SortOrder=1 and @SortColumn='ShippingMethod')  THEN ShippingMethod END ASC,
				CASE WHEN (@SortOrder=1 and @SortColumn='timeHrs')  THEN timeHrs END ASC,
				CASE WHEN (@SortOrder=1 and @SortColumn='QtyShipped')  THEN QtyShipped END ASC,
				CASE WHEN (@SortOrder=1 and @SortColumn='QtyRemaining')  THEN QtyRemaining END ASC,
				CASE WHEN (@SortOrder=1 and @SortColumn='PROMISEDDATE')  THEN PROMISEDDATE END ASC,
				CASE WHEN (@SortOrder=1 and @SortColumn='Status')  THEN Status END ASC,
				CASE WHEN (@SortOrder=1 and @SortColumn='PRIORITY')  THEN Priority END ASC,
				CASE WHEN (@SortOrder=1 and @SortColumn='AirwayBill')  THEN AirwayBill END ASC,

				CASE WHEN (@SortOrder=-1 and @SortColumn='MODULE')  THEN Module END DESC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='REFID')  THEN RefId END DESC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='RefNumber')  THEN RefNumber END DESC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='Customer')  THEN Customer END DESC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='PARTNUMBER')  THEN PartNumber END DESC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='PARTDESCRIPTION')  THEN PartDescription END DESC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='Carrier')  THEN Carrier END DESC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='ShippingMethod')  THEN ShippingMethod END DESC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='timeHrs')  THEN timeHrs END DESC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='QtyShipped')  THEN QtyShipped END DESC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='QtyRemaining')  THEN QtyRemaining END DESC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='PROMISEDDATE')  THEN PromisedDate END DESC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='STATUS')  THEN Status END DESC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='PRIORITY')  THEN Priority END DESC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='AirwayBill')  THEN AirwayBill END DESC

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
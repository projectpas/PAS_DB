-- =============================================
-- Author:		<Ayesha Sultana>
-- Create date: <7/8/2023>
-- Description:	<Search Shipping List Data>
-- =============================================

/**************************************************************             
  ** Change History             
 **************************************************************             
 ** PR   Date						 Author							Change Description              
 ** --   --------					 -------						-------------------------------            
    1    23/08/2023				 Ayesha Sultana						Filter Changes & bug fixes
	2    24/08/2023				 Ayesha Sultana						vendor rma changes & sorting fixes
	2    28/08/2023				 Ayesha Sultana						ShipVia & ShipDate fetch
	4    11/09/2023				 Ayesha Sultana						BUG FIXES ON RECORD COUNT
**************************************************************/ 
CREATE     PROCEDURE [dbo].[SearchShippingListData] 
	@PageNumber int,
	@PageSize int,
	@SortColumn varchar(50) = null,
	@SortOrder int = -1,
	@StatusID int,
	@GlobalFilter varchar(50) = null,
	@RefId bigint = null,
	@Customer varchar(50) = null,
	@PartNumber varchar(50) = null,
	@PartDescription varchar(100) = null,
	@Priority varchar(50) = null,
	@Status varchar(50) = null,
	@RefNumber varchar(50) = null,
    @IsDeleted bit = null,
	@MasterCompanyId int = null,
	@EmployeeId bigint = 1,
	@ShipVia varchar(50) = null,
	@ShipDate datetime = null,
	@AWB varchar(50) = null,
	@FilterListAs varchar(50) 
AS
BEGIN

	BEGIN TRY
		BEGIN TRANSACTION
			BEGIN
				
				DECLARE @RecordFrom int;
				DECLARE @POModuleId int =5;
				DECLARE @ROModuleId int =25;
				
				SET @RecordFrom = (@PageNumber-1) * @PageSize;
				-- SET @SortOrder=-1;
				
				IF @SortColumn IS NULL
				BEGIN
					SET @SortColumn = 'ShipDate';
					SET @SortOrder=-1;
				END 
				ELSE
				BEGIN 
					SET @SortColumn = Upper(@SortColumn)
				END
		
			
				-------- Get ALL List data for both 'ready o ship' & 'shipped'----------
				IF (@FilterListAs = 'all')

				BEGIN
				
					;With Result AS(
							   
					SELECT  wop.WorkOrderId as RefId,
							wo.WorkOrderNum as RefNumber,
							imt.partnumber,
							imt.PartDescription,
							wo.CustomerName as Customer,
							wo.CustomerId as CustomerId,
							P.Description as Priority,
							CASE WHEN WOS.AirwayBill IS NOT NULL THEN 'Shipped' ELSE 'Ready to ship' END AS 'Status',
							CASE WHEN WOS.AirwayBill IS NOT NULL THEN cast(wos.ShipDate AS DATE) ELSE cast(wopt.ConfirmedDate AS DATE) END AS ShipDate,
							CASE WHEN WOS.AirwayBill IS NOT NULL THEN SV.Name ELSE '' END as ShipVia,
							wos.AirwayBill as AWB,
							'WO' as ModuleName,
							WOP.ID AS PartId,
							wopt.PickTicketId as PickTicketId,
							wos.WorkOrderShippingId as ShippingId,
							WOSI.QtyShipped AS QtyShipped,
							WOPSI.PackagingSlipId AS PackagingSlipId,
							0 AS VendorRMADetailId

					FROM DBO.WOPickTicket wopt WITH (NOLOCK) 
							INNER JOIN DBO.WorkOrderPartNumber wop WITH (NOLOCK)  ON wopt.WorkorderId = wop.WorkorderId  AND wopt.OrderPartId = wop.ID
							INNER JOIN DBO.WorkOrder wo WITH (NOLOCK)  ON wo.WorkOrderId = wop.WorkOrderId
							LEFT JOIN DBO.WorkOrderShipping wos WITH (NOLOCK)  ON wos.WorkOrderId = wo.WorkOrderId
							LEFT JOIN DBO.ItemMaster imt  WITH (NOLOCK) on imt.ItemMasterId = wop.ItemMasterId
							LEFT JOIN DBO.Priority P WITH (NOLOCK)  ON P.PriorityId = wop.WorkOrderPriorityId
							LEFT JOIN WorkOrderShippingItem WOSI WITH (NOLOCK) ON WOSI.WorkOrderShippingId = WOS.WorkOrderShippingId AND WOSI.WOPickTicketId=WOPT.PickTicketId
							LEFT JOIN WorkOrderPackaginSlipItems WOPSI WITH (NOLOCK) ON WOPSI.WOPartNoId = WOP.ID AND WOPSI.WOPickTicketId=WOPT.PickTicketId
							LEFT JOIN DBO.ShippingVia SV WITH (NOLOCK)  ON SV.ShippingViaId = wos.ShipViaId -- and SV.IsPrimary=1

					WHERE wopt.IsDeleted = 0 and wopt.MasterCompanyId= @MasterCompanyId and wo.IsDeleted = 0  and wopt.IsConfirmed=1 

					GROUP BY wop.WorkOrderId,wo.WorkOrderNum,imt.partnumber,imt.PartDescription,wo.CustomerName,wo.customerId,P.Description,WOS.AirwayBill,
								wos.ShipDate,SV.Name,wos.AirwayBill,WOP.ID,wopt.PickTicketId,wos.WorkOrderShippingId,WOSI.QtyShipped,WOPSI.PackagingSlipId,wopt.ConfirmedDate

					UNION

					SELECT  SOP.SalesOrderId as RefId,
							SO.SalesOrderNumber as RefNumber,	
							ITM.partnumber,
							ITM.PartDescription,
							SO.CustomerName as Customer,
							SO.CustomerId as CustomerId,
							P.Description as Priority,
							CASE WHEN SOS.AirwayBill IS NOT NULL THEN 'Shipped' ELSE 'Ready to ship' END AS 'Status',	
							CASE WHEN SOS.AirwayBill IS NOT NULL THEN cast(SOS.ShipDate as date) ELSE cast(sopt.ConfirmedDate as date) END AS ShipDate,
							CASE WHEN SOS.AirwayBill IS NOT NULL THEN SV.Name ELSE '' END as ShipVia,
							SOS.AirwayBill AS AWB,
							'SO' as ModuleName,
							SOP.SalesOrderPartId as PartId,
							SOPT.SOPickTicketId as PickTicketId,
							sos.SalesOrderShippingId as ShippingId,
							SUM(ISNULL(SOSI.QtyShipped,0)) AS QtyShipped,
							SOPSI.PackagingSlipId AS PackagingSlipId,
							0 AS VendorRMADetailId

					FROM DBO.SalesOrderPart sop WITH (NOLOCK)
						LEFT JOIN DBO.SalesOrder so WITH (NOLOCK) ON so.SalesOrderId = sop.SalesOrderId
						LEFT JOIN DBO.SalesOrderShipping SOS WITH (NOLOCK) ON SOS.SalesOrderId = SO.SalesOrderId
						INNER JOIN DBO.SOPickTicket sopt WITH (NOLOCK) ON sopt.SalesOrderId = sop.SalesOrderId AND sopt.SalesOrderPartId = sop.SalesOrderPartId
						LEFT JOIN SalesOrderShippingItem SOSI WITH (NOLOCK) ON SOSI.SalesOrderShippingId = SOS.SalesOrderShippingId and sosi.SOPickTicketId = sopt.SOPickTicketId
						LEFT JOIN SalesOrderPackaginSlipItems SOPSI WITH (NOLOCK) ON SOPSI.SalesOrderPartId = SOP.SalesOrderPartId and SOPSI.SOPickTicketId = sopt.SOPickTicketId					
						LEFT JOIN DBO.ItemMaster ITM WITH (NOLOCK) ON ITM.ItemMasterId = sop.ItemMasterId
						LEFT JOIN DBO.Priority P WITH (NOLOCK)  ON P.PriorityId = sop.PriorityId
						LEFT JOIN DBO.ShippingVia SV WITH (NOLOCK)  ON SV.ShippingViaId = sos.ShipViaId -- and SV.IsPrimary=1

					WHERE  sopt.IsDeleted = 0 and sopt.MasterCompanyId= @MasterCompanyId AND sopt.IsConfirmed = 1
						
					GROUP BY SOP.SalesOrderId,SO.SalesOrderNumber,ITM.partnumber,ITM.PartDescription,SO.CustomerName,SO.CustomerId,P.Description,SOS.AirwayBill,SV.Name,
								SOS.ShipDate,SOS.AirwayBill,SOP.SalesOrderPartId,SOPT.SOPickTicketId, SO.customerId, sos.SalesOrderShippingId,SOSI.QtyShipped,SOPSI.PackagingSlipId
								,sopt.ConfirmedDate
				
					UNION

					SELECT sop.ExchangeSalesOrderId as RefId,
								so.ExchangeSalesOrderNumber as RefNumber,
								ITM.partnumber,
								ITM.PartDescription,
								so.CustomerName as Customer,
								so.CustomerId as CustomerId,
								P.Description as Priority,
								CASE WHEN SOS.AirwayBill IS NOT NULL THEN 'Shipped' ELSE 'Ready to ship' END AS 'Status',	
								CASE WHEN SOS.AirwayBill IS NOT NULL THEN cast(SOS.ShipDate as date) ELSE cast(sopt.ConfirmedDate as date) END AS ShipDate,
								CASE WHEN SOS.AirwayBill IS NOT NULL THEN SV.Name ELSE '' END as ShipVia,
								SOS.AirwayBill AS AWB,
								'ESO' AS 'ModuleName',
								sop.ExchangeSalesOrderPartId as PartId,
								SOPT.SOPickTicketId as PickTicketId,
								sos.ExchangeSalesOrderShippingId as ShippingId,
								SOSI.QtyShipped AS QtyShipped,
								SOPSI.PackagingSlipId AS PackagingSlipId,
								0 AS VendorRMADetailId
						
					FROM DBO.ExchangeSalesOrderPart sop WITH (NOLOCK)
							LEFT JOIN DBO.ExchangeSalesOrder so WITH (NOLOCK) on so.ExchangeSalesOrderId = sop.ExchangeSalesOrderId
							LEFT JOIN DBO.ExchangeSalesOrderShipping SOS WITH (NOLOCK) ON SOS.ExchangeSalesOrderId = SO.ExchangeSalesOrderId
							INNER JOIN DBO.ExchangeSOPickTicket sopt WITH (NOLOCK) on sopt.ExchangeSalesOrderId = sop.ExchangeSalesOrderId AND sopt.ExchangeSalesOrderPartId = sop.ExchangeSalesOrderPartId
							LEFT JOIN DBO.ItemMaster ITM WITH (NOLOCK) on ITM.ItemMasterId = sop.ItemMasterId
							LEFT JOIN DBO.Priority P WITH (NOLOCK)  ON P.PriorityId = sop.PriorityId
							LEFT JOIN ExchangeSalesOrderShippingItem SOSI WITH (NOLOCK) ON SOSI.ExchangeSalesOrderShippingId = SOS.ExchangeSalesOrderShippingId AND sosi.SOPickTicketId = sopt.SOPickTicketId
							LEFT JOIN ExchangeSalesOrderPackaginSlipItems SOPSI WITH (NOLOCK) ON SOPSI.ExchangeSalesOrderPartId = SOP.ExchangeSalesOrderPartId and SOPSI.SOPickTicketId = sopt.SOPickTicketId
							LEFT JOIN DBO.ShippingVia SV WITH (NOLOCK)  ON SV.ShippingViaId = sos.ShipViaId -- and SV.IsPrimary=1

					WHERE  sopt.IsDeleted = 0 and sopt.MasterCompanyId= @MasterCompanyId  and so.IsDeleted = 0  and sopt.IsConfirmed = 1

					GROUP BY sop.ExchangeSalesOrderId,so.ExchangeSalesOrderNumber,ITM.partnumber,ITM.PartDescription,so.CustomerName,so.customerId,P.Description,SOS.AirwayBill,
								SV.Name,SOS.ShipDate,SOS.AirwayBill,sop.ExchangeSalesOrderPartId,SOPT.SOPickTicketId,sos.ExchangeSalesOrderShippingId,SOSI.QtyShipped,SOPSI.PackagingSlipId
								,sopt.ConfirmedDate

					UNION	

					SELECT DISTINCT VD.VendorRMAId as RefId,
							VR.RMANumber as RefNumber,
							IMT.partnumber,
							IMT.PartDescription,
							V.VendorName as Customer,
							v.VendorId as CustomerId,
							IMT.Priority as Priority,
							CASE WHEN RS.AirwayBill IS NOT NULL THEN 'Shipped' ELSE 'Ready to ship' END AS 'Status',
							CASE WHEN RS.AirwayBill IS NOT NULL THEN cast(RS.ShipDate AS DATE) ELSE cast(Rpt.ConfirmedDate AS DATE) END AS ShipDate,
							CASE WHEN RS.AirwayBill IS NOT NULL THEN SV.Name ELSE '' END as ShipVia,
							RS.AirwayBill as AWB,
							'VENDOR RMA' AS ModuleName,
							IMT.ItemMasterId as PartId,
							RPT.RMAPickTicketId AS PickTicketId,
							RS.RMAShippingId AS ShippingId,
							RSI.QtyShipped AS QtyShipped,
							RPSI.PackagingSlipId AS PackagingSlipId,
							VD.VendorRMADetailId AS VendorRMADetailId

					FROM [dbo].[VendorRMADetail] VD WITH(NOLOCK) 
						  -- INNER JOIN [dbo].[Stockline] SL WITH (NOLOCK) ON VD.[StockLineId] = SL.[StockLineId]
						  INNER JOIN VendorRMA VR WITH (NOLOCK) ON VD.VendorRMAId = VR.VendorRMAId
						  INNER JOIN [dbo].[ItemMaster] IMT WITH (NOLOCK) ON VD.[ItemMasterId] = imt.[ItemMasterId]
						  LEFT JOIN RMAShipping RS WITH (NOLOCK) ON VD.VendorRMAId=RS.VendorRMAId
						  INNER JOIN Vendor V WITH (NOLOCK) ON VR.VENDORID = V.VendorId						 
						  LEFT JOIN RMAPickTicket RPT WITH (NOLOCK) ON VD.VendorRMADetailId = RPT.VendorRMADetailId
						  LEFT JOIN RMAShippingItem RSI WITH (NOLOCK) ON RSI.RMAShippingId=RS.RMAShippingId and RSI.RMAPickTicketId = RPT.RMAPickTicketId
						  LEFT JOIN VendorRMAPackaginSlipItems RPSI WITH (NOLOCK) ON RPSI.VendorRMADetailId = VD.VendorRMADetailId and RPSI.RMAPickTicketId = RPT.RMAPickTicketId
						  LEFT JOIN DBO.ShippingVia SV WITH (NOLOCK) ON SV.ShippingViaId = RS.ShipViaId -- and SV.IsPrimary=1

					 WHERE  RPT.IsDeleted = 0 and RPT.MasterCompanyId= @MasterCompanyId  and vr.IsDeleted = 0  and RPT.IsConfirmed = 1
					 	--and RPT.RMAPickTicketId not in(SELECT RMAPickTicketId FROM DBO.RMAShippingItem RSI 
							--			WHERE RSI.IsDeleted = 0) 

					GROUP BY VD.VendorRMAId,VR.RMANumber,IMT.partnumber,IMT.PartDescription,V.VendorName,v.VendorId,IMT.[Priority],RS.AirwayBill,RPT.ConfirmedDate,RS.AirwayBill,
								IMT.ItemMasterId , RPT.RMAPickTicketId , RS.RMAShippingId,RSI.QtyShipped ,RPSI.PackagingSlipId ,VD.VendorRMADetailId,RS.ShipDate,SV.Name

						),
							FinalResult AS (

							SELECT RefId,RefNumber,PartNumber,PartDescription,Customer,CustomerId,[Priority],[Status],ShipVia,ShipDate,AWB,ModuleName,PartId,PickTicketId,ShippingId,QtyShipped,
										PackagingSlipId,VendorRMADetailId
										
				
							FROM Result 
							where (
								(@GlobalFilter <> '' AND ((RefNumber like '%' + @GlobalFilter +'%') OR
										(PartNumber like '%' + @GlobalFilter +'%') OR
										(PartDescription like '%'+ @GlobalFilter +'%') OR
										(Customer like '%' + @GlobalFilter +'%') OR
										(CustomerId like '%' + @GlobalFilter +'%') OR
										(Priority like '%' + @GlobalFilter +'%') OR
										(Status like '%' + @GlobalFilter +'%')OR
										(ShipVia like '%' + @GlobalFilter +'%') OR
										-- (ShipDate like '%' + @GlobalFilter +'%') OR
										(AWB  LIKE '%' +@GlobalFilter+'%') 
										))
										OR   
										(@GlobalFilter = '' AND 
										(ISNULL(@RefNumber, '') = '' OR RefNumber like  '%'+ @RefNumber +'%') and
										(ISNULL(@PartNumber, '') = '' OR PartNumber like '%'+ @PartNumber +'%') and
										(ISNULL(@PartDescription, '') = '' OR PartDescription like '%'+ @PartDescription +'%') and
										(ISNULL(@Customer, '') = '' OR Customer like '%'+ @Customer +'%') and
										(ISNULL(@Priority, '') = '' OR [Priority] like '%'+ @Priority +'%') and
										(ISNULL(@Status,'') ='' OR [Status] like  '%'+@Status+'%') and
										(ISNULL(@ShipVia, '') = '' OR ShipVia like '%'+ @ShipVia +'%') and
										(ISNULL(@ShipDate, '') = '' OR cast(ShipDate as date) = cast(@ShipDate as date))  and
										(ISNULL(@AWB, '') = '' OR AWB like '%'+ @AWB+'%') 
										))),
								ResultCount AS (Select COUNT(RefId) AS NumberOfItems FROM FinalResult)


								SELECT RefId,RefNumber,PartNumber,PartDescription,Customer,CustomerId,[Priority],[Status],ShipVia,ShipDate,AWB,ModuleName,PartId,PickTicketId,ShippingId,QtyShipped,
										PackagingSlipId,VendorRMADetailId,NumberOfItems
					
								FROM FinalResult, ResultCount

								ORDER BY  
									CASE WHEN (@SortOrder=1 and @SortColumn='REFID')  THEN RefId END ASC,
									CASE WHEN (@SortOrder=1 and @SortColumn='RefNumber')  THEN RefNumber END ASC,
									CASE WHEN (@SortOrder=1 and @SortColumn='PARTNUMBER')  THEN PartNumber END ASC,
									CASE WHEN (@SortOrder=1 and @SortColumn='PARTDESCRIPTION')  THEN PartDescription END ASC,
									CASE WHEN (@SortOrder=1 and @SortColumn='Customer')  THEN Customer END ASC,
									CASE WHEN (@SortOrder=1 and @SortColumn='CustomerId')  THEN CustomerId END ASC,
									CASE WHEN (@SortOrder=1 and @SortColumn='PRIORITY')  THEN [Priority] END ASC,
									CASE WHEN (@SortOrder=1 and @SortColumn='Status')  THEN [Status] END ASC,
									CASE WHEN (@SortOrder=1 and @SortColumn='ShipVia')  THEN ShipVia END ASC,
									CASE WHEN (@SortOrder=1 and @SortColumn='ShipDate')  THEN ShipDate END ASC,
									CASE WHEN (@SortOrder=1 and @SortColumn='AWB')  THEN AWB END ASC,
									CASE WHEN (@SortOrder=1 and @SortColumn='ModuleName')  THEN ModuleName END ASC,
									CASE WHEN (@SortOrder=1 and @SortColumn='PartId')  THEN PartId END ASC,
									CASE WHEN (@SortOrder=1 and @SortColumn='PickTicketId')  THEN PickTicketId END ASC,
									CASE WHEN (@SortOrder=1 and @SortColumn='ShippingId')  THEN ShippingId END ASC,
				
									CASE WHEN (@SortOrder=-1 and @SortColumn='REFID')  THEN RefId END DESC,
									CASE WHEN (@SortOrder=-1 and @SortColumn='RefNumber')  THEN RefNumber END DESC,
									CASE WHEN (@SortOrder=-1 and @SortColumn='PARTNUMBER')  THEN PartNumber END DESC,
									CASE WHEN (@SortOrder=-1 and @SortColumn='PARTDESCRIPTION')  THEN PartDescription END DESC,
									CASE WHEN (@SortOrder=-1 and @SortColumn='Customer')  THEN Customer END DESC,
									CASE WHEN (@SortOrder=-1 and @SortColumn='CustomerId')  THEN CustomerId END DESC,
									CASE WHEN (@SortOrder=-1 and @SortColumn='PRIORITY')  THEN [Priority] END DESC,
									CASE WHEN (@SortOrder=-1 and @SortColumn='STATUS')  THEN [Status] END DESC,
									CASE WHEN (@SortOrder=-1 and @SortColumn='ShipVia')  THEN ShipVia END DESC,
									CASE WHEN (@SortOrder=-1 and @SortColumn='ShipDate')  THEN ShipDate END DESC,
									CASE WHEN (@SortOrder=-1 and @SortColumn='AWB')  THEN AWB END DESC,				
									CASE WHEN (@SortOrder=-1 and @SortColumn='ModuleName')  THEN ModuleName END DESC,
									CASE WHEN (@SortOrder=-1 and @SortColumn='PartId')  THEN PartId END DESC,
									CASE WHEN (@SortOrder=-1 and @SortColumn='PickTicketId')  THEN PickTicketId END DESC,
									CASE WHEN (@SortOrder=-1 and @SortColumn='ShippingId')  THEN ShippingId END DESC
								OFFSET @RecordFrom ROWS 
								FETCH NEXT @PageSize ROWS ONLY			
			
				END

				-------- Get SHIPPED list----------
				ELSE IF(@FilterListAs = 'shipped')

				BEGIN
				
					;With Result AS(
							   
					SELECT  wop.WorkOrderId as RefId,
							wo.WorkOrderNum as RefNumber,
							imt.partnumber,
							imt.PartDescription,
							wo.CustomerName as Customer,
							wo.CustomerId as CustomerId,
							P.Description as Priority,
							'Shipped' AS 'Status',
							cast(wos.ShipDate AS DATE) AS ShipDate,
							SV.Name as ShipVia,
							wos.AirwayBill as AWB,
							'WO' as ModuleName,
							WOP.ID AS PartId,
							wopt.PickTicketId as PickTicketId,
							wos.WorkOrderShippingId as ShippingId,
							WOSI.QtyShipped AS QtyShipped,
							WOPSI.PackagingSlipId AS PackagingSlipId,
							0 AS VendorRMADetailId

					FROM DBO.WOPickTicket wopt WITH (NOLOCK) 
							INNER JOIN DBO.WorkOrderPartNumber wop WITH (NOLOCK)  ON wopt.WorkorderId = wop.WorkorderId  AND wopt.OrderPartId = wop.ID
							INNER JOIN DBO.WorkOrder wo WITH (NOLOCK)  ON wo.WorkOrderId = wop.WorkOrderId
							LEFT JOIN DBO.WorkOrderShipping wos WITH (NOLOCK)  ON wos.WorkOrderId = wo.WorkOrderId
							LEFT JOIN DBO.ItemMaster imt  WITH (NOLOCK) on imt.ItemMasterId = wop.ItemMasterId
							LEFT JOIN DBO.Priority P WITH (NOLOCK)  ON P.PriorityId = wop.WorkOrderPriorityId
							LEFT JOIN WorkOrderShippingItem WOSI WITH (NOLOCK) ON WOSI.WorkOrderShippingId = WOS.WorkOrderShippingId AND WOSI.WOPickTicketId=WOPT.PickTicketId
							LEFT JOIN WorkOrderPackaginSlipItems WOPSI WITH (NOLOCK) ON WOPSI.WOPartNoId = WOP.ID AND WOPSI.WOPickTicketId=WOPT.PickTicketId
							LEFT JOIN DBO.ShippingVia SV WITH (NOLOCK)  ON SV.ShippingViaId = wos.ShipViaId -- and sv.CustomerId=wos.customerid and SV.IsPrimary=1

					WHERE wopt.IsDeleted = 0 and wopt.MasterCompanyId= @MasterCompanyId and wo.IsDeleted = 0  and wopt.IsConfirmed=1 AND WOS.AirwayBill IS NOT NULL

					GROUP BY wop.WorkOrderId,wo.WorkOrderNum,imt.partnumber,imt.PartDescription,wo.CustomerName,wo.customerId,P.Description,WOS.AirwayBill,
								wos.ShipDate,SV.Name,wos.AirwayBill,WOP.ID,wopt.PickTicketId,wos.WorkOrderShippingId,WOSI.QtyShipped,WOPSI.PackagingSlipId

					UNION

					SELECT DISTINCT SOP.SalesOrderId as RefId,
							SO.SalesOrderNumber as RefNumber,	
							ITM.partnumber,
							ITM.PartDescription,
							SO.CustomerName as Customer,
							SO.CustomerId as CustomerId,
							P.Description as Priority,
							'Shipped' AS 'Status',	
							cast(SOS.ShipDate as date) AS ShipDate,
							SV.Name as ShipVia,
							SOS.AirwayBill AS AWB,
							'SO' as ModuleName,
							SOP.SalesOrderPartId as PartId,
							SOPT.SOPickTicketId as PickTicketId,
							sos.SalesOrderShippingId as ShippingId,
							SUM(ISNULL(SOSI.QtyShipped,0)) AS QtyShipped,
							SOPSI.PackagingSlipId AS PackagingSlipId,
							0 AS VendorRMADetailId

					FROM DBO.SalesOrderPart sop WITH (NOLOCK)
							LEFT JOIN DBO.SalesOrder so WITH (NOLOCK) ON so.SalesOrderId = sop.SalesOrderId
							LEFT JOIN DBO.SalesOrderShipping SOS WITH (NOLOCK) ON SOS.SalesOrderId = SO.SalesOrderId
							INNER JOIN DBO.SOPickTicket sopt WITH (NOLOCK) ON sopt.SalesOrderId = sop.SalesOrderId AND sopt.SalesOrderPartId = sop.SalesOrderPartId
							LEFT JOIN SalesOrderShippingItem SOSI WITH (NOLOCK) ON SOSI.SalesOrderShippingId = SOS.SalesOrderShippingId and sosi.SOPickTicketId = sopt.SOPickTicketId
							LEFT JOIN SalesOrderPackaginSlipItems SOPSI WITH (NOLOCK) ON SOPSI.SalesOrderPartId = SOP.SalesOrderPartId and SOPSI.SOPickTicketId = sopt.SOPickTicketId					
							LEFT JOIN DBO.ItemMaster ITM WITH (NOLOCK) ON ITM.ItemMasterId = sop.ItemMasterId
							LEFT JOIN DBO.Priority P WITH (NOLOCK)  ON P.PriorityId = sop.PriorityId
							LEFT JOIN DBO.ShippingVia SV WITH (NOLOCK) ON SV.ShippingViaId = sos.ShipViaId -- and SV.CustomerId=sos.CustomerId -- and sv.IsPrimary=1

					WHERE  sopt.IsDeleted = 0 and sopt.MasterCompanyId= @MasterCompanyId AND sopt.IsConfirmed = 1	AND SOS.AirwayBill IS NOT NULL			
						
					GROUP BY SOP.SalesOrderId,SO.SalesOrderNumber,ITM.partnumber,ITM.PartDescription,SO.CustomerName,SO.CustomerId,P.Description,SOS.AirwayBill,SV.Name,
								SOS.ShipDate,SOS.AirwayBill,SOP.SalesOrderPartId,SOPT.SOPickTicketId, SO.customerId, sos.SalesOrderShippingId,SOSI.QtyShipped,SOPSI.PackagingSlipId
				
					UNION

					SELECT sop.ExchangeSalesOrderId as RefId,
								so.ExchangeSalesOrderNumber as RefNumber,
								ITM.partnumber,
								ITM.PartDescription,
								so.CustomerName as Customer,
								so.CustomerId as CustomerId,
								P.Description as Priority,
								'Shipped' AS 'Status',	
								cast(SOS.ShipDate as date) AS ShipDate,
								SV.Name as ShipVia,
								SOS.AirwayBill AS AWB,
								'ESO' AS 'ModuleName',
								sop.ExchangeSalesOrderPartId as PartId,
								SOPT.SOPickTicketId as PickTicketId,
								sos.ExchangeSalesOrderShippingId as ShippingId,
								SOSI.QtyShipped AS QtyShipped,
								SOPSI.PackagingSlipId AS PackagingSlipId,
								0 AS VendorRMADetailId
						
					FROM DBO.ExchangeSalesOrderPart sop WITH (NOLOCK)
							LEFT JOIN DBO.ExchangeSalesOrder so WITH (NOLOCK) on so.ExchangeSalesOrderId = sop.ExchangeSalesOrderId
							LEFT JOIN DBO.ExchangeSalesOrderShipping SOS WITH (NOLOCK) ON SOS.ExchangeSalesOrderId = SO.ExchangeSalesOrderId
							INNER JOIN DBO.ExchangeSOPickTicket sopt WITH (NOLOCK) on sopt.ExchangeSalesOrderId = sop.ExchangeSalesOrderId AND sopt.ExchangeSalesOrderPartId = sop.ExchangeSalesOrderPartId
							LEFT JOIN DBO.ItemMaster ITM WITH (NOLOCK) on ITM.ItemMasterId = sop.ItemMasterId
							LEFT JOIN DBO.Priority P WITH (NOLOCK)  ON P.PriorityId = sop.PriorityId
							LEFT JOIN ExchangeSalesOrderShippingItem SOSI WITH (NOLOCK) ON SOSI.ExchangeSalesOrderShippingId = SOS.ExchangeSalesOrderShippingId AND sosi.SOPickTicketId = sopt.SOPickTicketId
							LEFT JOIN ExchangeSalesOrderPackaginSlipItems SOPSI WITH (NOLOCK) ON SOPSI.ExchangeSalesOrderPartId = SOP.ExchangeSalesOrderPartId and SOPSI.SOPickTicketId = sopt.SOPickTicketId
							LEFT JOIN DBO.ShippingVia SV WITH (NOLOCK)  ON SV.ShippingViaId = sos.ShipViaId -- and sv.CustomerId=sos.CustomerId and SV.IsPrimary=1

					WHERE  sopt.IsDeleted = 0 and sopt.MasterCompanyId= @MasterCompanyId  and so.IsDeleted = 0  and sopt.IsConfirmed = 1 AND SOS.AirwayBill IS NOT NULL

					GROUP BY sop.ExchangeSalesOrderId,so.ExchangeSalesOrderNumber,ITM.partnumber,ITM.PartDescription,so.CustomerName,so.customerId,P.Description,SOS.AirwayBill,
								SV.Name,SOS.ShipDate,SOS.AirwayBill,sop.ExchangeSalesOrderPartId,SOPT.SOPickTicketId,sos.ExchangeSalesOrderShippingId,SOSI.QtyShipped,SOPSI.PackagingSlipId
				
					UNION	

					SELECT VD.VendorRMAId as RefId,
							VR.RMANumber as RefNumber,
							IMT.partnumber,
							IMT.PartDescription,
							V.VendorName as Customer,
							v.VendorId as CustomerId,
							IMT.Priority as Priority,
							'Shipped' AS 'Status',
							cast(RS.ShipDate AS DATE) AS ShipDate,
							SV.Name as ShipVia,
							RS.AirwayBill as AWB,
							'VENDOR RMA' AS ModuleName,
							IMT.RevisedPartId as PartId,
							RPT.RMAPickTicketId AS PickTicketId,
							RS.RMAShippingId AS ShippingId,
							RSI.QtyShipped AS QtyShipped,
							RPSI.PackagingSlipId AS PackagingSlipId,
							VD.VendorRMADetailId AS VendorRMADetailId

					FROM [dbo].[VendorRMADetail] VD WITH(NOLOCK) 
						  -- INNER JOIN [dbo].[Stockline] SL WITH (NOLOCK) ON VD.[StockLineId] = SL.[StockLineId]
						  INNER JOIN VendorRMA VR WITH (NOLOCK) ON VD.VendorRMAId = VR.VendorRMAId
						  INNER JOIN [dbo].[ItemMaster] IMT WITH (NOLOCK) ON VD.[ItemMasterId] = imt.[ItemMasterId]
						  LEFT JOIN RMAShipping RS WITH (NOLOCK) ON VD.VendorRMAId=RS.VendorRMAId
						  INNER JOIN Vendor V WITH (NOLOCK) ON VR.VENDORID = V.VendorId						 
						  LEFT JOIN RMAPickTicket RPT WITH (NOLOCK) ON VD.VendorRMADetailId = RPT.VendorRMADetailId
						  LEFT JOIN RMAShippingItem RSI WITH (NOLOCK) ON RSI.RMAShippingId=RS.RMAShippingId and RSI.RMAPickTicketId = RPT.RMAPickTicketId
						  LEFT JOIN VendorRMAPackaginSlipItems RPSI WITH (NOLOCK) ON RPSI.VendorRMADetailId = VD.VendorRMADetailId and RPSI.RMAPickTicketId = RPT.RMAPickTicketId
						  LEFT JOIN DBO.ShippingVia SV WITH (NOLOCK) ON SV.ShippingViaId = RS.ShipViaId -- and SV.IsPrimary=1

					 WHERE  RPT.IsDeleted = 0 and RPT.MasterCompanyId= @MasterCompanyId  and vr.IsDeleted = 0 and RPT.IsConfirmed = 1 AND  RS.AirwayBill IS NOT NULL

					 GROUP BY VD.VendorRMAId,VR.RMANumber,IMT.partnumber,IMT.PartDescription,V.VendorName,v.VendorId,IMT.[Priority],RS.AirwayBill,RS.ShipDate,SV.Name,RS.AirwayBill,
								IMT.RevisedPartId , RPT.RMAPickTicketId , RS.RMAShippingId,RSI.QtyShipped ,RPSI.PackagingSlipId ,VD.VendorRMADetailId

						),
							FinalResult AS (

							SELECT RefId,RefNumber,PartNumber,PartDescription,Customer,CustomerId,[Priority],[Status],ShipVia,ShipDate,AWB,ModuleName,PartId,PickTicketId,ShippingId,QtyShipped,
										PackagingSlipId,VendorRMADetailId
										
				
							FROM Result 
							where (
								(@GlobalFilter <> '' AND ((RefNumber like '%' + @GlobalFilter +'%') OR
										(PartNumber like '%' + @GlobalFilter +'%') OR
										(PartDescription like '%'+ @GlobalFilter +'%') OR
										(Customer like '%' + @GlobalFilter +'%') OR
										(CustomerId like '%' + @GlobalFilter +'%') OR
										(Priority like '%' + @GlobalFilter +'%') OR
										(Status like '%' + @GlobalFilter +'%')OR
										(ShipVia like '%' + @GlobalFilter +'%') OR
										-- (ShipDate like '%' + @GlobalFilter +'%') OR
										(AWB  LIKE '%' +@GlobalFilter+'%') 
										))
										OR   
										(@GlobalFilter = '' AND 
										(ISNULL(@RefNumber, '') = '' OR RefNumber like  '%'+ @RefNumber +'%') and
										(ISNULL(@PartNumber, '') = '' OR PartNumber like '%'+ @PartNumber +'%') and
										(ISNULL(@PartDescription, '') = '' OR PartDescription like '%'+ @PartDescription +'%') and
										(ISNULL(@Customer, '') = '' OR Customer like '%'+ @Customer +'%') and
										(ISNULL(@Priority, '') = '' OR [Priority] like '%'+ @Priority +'%') and
										(ISNULL(@Status,'') ='' OR [Status] like  '%'+@Status+'%') and
										(ISNULL(@ShipVia, '') = '' OR ShipVia like '%'+ @ShipVia +'%') and
										(ISNULL(@ShipDate, '') = '' OR cast(ShipDate as date) = cast(@ShipDate as date))  and
										(ISNULL(@AWB, '') = '' OR AWB like '%'+ @AWB+'%') 
										))),
								ResultCount AS (Select COUNT(RefId) AS NumberOfItems FROM FinalResult)


								SELECT RefId,RefNumber,PartNumber,PartDescription,Customer,CustomerId,[Priority],[Status],ShipVia,ShipDate,AWB,ModuleName,PartId,PickTicketId,ShippingId,QtyShipped,
										PackagingSlipId,VendorRMADetailId,NumberOfItems
					
								FROM FinalResult, ResultCount

								ORDER BY  
									CASE WHEN (@SortOrder=1 and @SortColumn='REFID')  THEN RefId END ASC,
									CASE WHEN (@SortOrder=1 and @SortColumn='RefNumber')  THEN RefNumber END ASC,
									CASE WHEN (@SortOrder=1 and @SortColumn='PARTNUMBER')  THEN PartNumber END ASC,
									CASE WHEN (@SortOrder=1 and @SortColumn='PARTDESCRIPTION')  THEN PartDescription END ASC,
									CASE WHEN (@SortOrder=1 and @SortColumn='Customer')  THEN Customer END ASC,
									CASE WHEN (@SortOrder=1 and @SortColumn='CustomerId')  THEN CustomerId END ASC,
									CASE WHEN (@SortOrder=1 and @SortColumn='PRIORITY')  THEN [Priority] END ASC,
									CASE WHEN (@SortOrder=1 and @SortColumn='Status')  THEN [Status] END ASC,
									CASE WHEN (@SortOrder=1 and @SortColumn='ShipVia')  THEN ShipVia END ASC,
									CASE WHEN (@SortOrder=1 and @SortColumn='ShipDate')  THEN ShipDate END ASC,
									CASE WHEN (@SortOrder=1 and @SortColumn='AWB')  THEN AWB END ASC,
									CASE WHEN (@SortOrder=1 and @SortColumn='ModuleName')  THEN ModuleName END ASC,
									CASE WHEN (@SortOrder=1 and @SortColumn='PartId')  THEN PartId END ASC,
									CASE WHEN (@SortOrder=1 and @SortColumn='PickTicketId')  THEN PickTicketId END ASC,
									CASE WHEN (@SortOrder=1 and @SortColumn='ShippingId')  THEN ShippingId END ASC,
				
									CASE WHEN (@SortOrder=-1 and @SortColumn='REFID')  THEN RefId END DESC,
									CASE WHEN (@SortOrder=-1 and @SortColumn='RefNumber')  THEN RefNumber END DESC,
									CASE WHEN (@SortOrder=-1 and @SortColumn='PARTNUMBER')  THEN PartNumber END DESC,
									CASE WHEN (@SortOrder=-1 and @SortColumn='PARTDESCRIPTION')  THEN PartDescription END DESC,
									CASE WHEN (@SortOrder=-1 and @SortColumn='Customer')  THEN Customer END DESC,
									CASE WHEN (@SortOrder=-1 and @SortColumn='CustomerId')  THEN CustomerId END DESC,
									CASE WHEN (@SortOrder=-1 and @SortColumn='PRIORITY')  THEN [Priority] END DESC,
									CASE WHEN (@SortOrder=-1 and @SortColumn='STATUS')  THEN [Status] END DESC,
									CASE WHEN (@SortOrder=-1 and @SortColumn='ShipVia')  THEN ShipVia END DESC,
									CASE WHEN (@SortOrder=-1 and @SortColumn='ShipDate')  THEN ShipDate END DESC,
									CASE WHEN (@SortOrder=-1 and @SortColumn='AWB')  THEN AWB END DESC,				
									CASE WHEN (@SortOrder=-1 and @SortColumn='ModuleName')  THEN ModuleName END DESC,
									CASE WHEN (@SortOrder=-1 and @SortColumn='PartId')  THEN PartId END DESC,
									CASE WHEN (@SortOrder=-1 and @SortColumn='PickTicketId')  THEN PickTicketId END DESC,
									CASE WHEN (@SortOrder=-1 and @SortColumn='ShippingId')  THEN ShippingId END DESC
								OFFSET @RecordFrom ROWS 
								FETCH NEXT @PageSize ROWS ONLY
				
				END
				
				-------- Get READYTOSHIP List----------
				ELSE BEGIN

					;With Result AS(
							   
					SELECT  WOP.WorkOrderId as RefId,
							WO.WorkOrderNum as RefNumber,
							IMT.partnumber,
							IMT.PartDescription,
							WO.CustomerName as Customer,
							WO.CustomerId as CustomerId,
							P.Description as Priority,
							'Ready to ship' AS 'Status',
							cast(wopt.ConfirmedDate AS DATE) AS ShipDate,
							'' as ShipVia,
							WOS.AirwayBill as AWB,
							'WO' as ModuleName,
							WOP.ID AS PartId,
							WOPT.PickTicketId as PickTicketId,
							WOS.WorkOrderShippingId as ShippingId,
							WOSI.QtyShipped AS QtyShipped,
							WOPSI.PackagingSlipId AS PackagingSlipId,
							0 AS VendorRMADetailId

					FROM DBO.WOPickTicket wopt WITH (NOLOCK) 
							INNER JOIN DBO.WorkOrderPartNumber wop WITH (NOLOCK)  ON wopt.WorkorderId = wop.WorkorderId  AND wopt.OrderPartId = wop.ID
							INNER JOIN DBO.WorkOrder wo WITH (NOLOCK)  ON wo.WorkOrderId = wop.WorkOrderId
							LEFT JOIN DBO.WorkOrderShipping wos WITH (NOLOCK)  ON wos.WorkOrderId = wo.WorkOrderId
							LEFT JOIN DBO.ItemMaster imt  WITH (NOLOCK) on imt.ItemMasterId = wop.ItemMasterId
							LEFT JOIN DBO.Priority P WITH (NOLOCK)  ON P.PriorityId = wop.WorkOrderPriorityId
							LEFT JOIN WorkOrderShippingItem WOSI WITH (NOLOCK) ON WOSI.WorkOrderShippingId = WOS.WorkOrderShippingId AND WOSI.WOPickTicketId=WOPT.PickTicketId
							LEFT JOIN WorkOrderPackaginSlipItems WOPSI WITH (NOLOCK) ON WOPSI.WOPartNoId = WOP.ID AND WOPSI.WOPickTicketId=WOPT.PickTicketId
							LEFT JOIN DBO.CustomerDomensticShippingShipVia SV WITH (NOLOCK)  ON SV.CustomerId = wo.CustomerId and SV.IsPrimary=1

					WHERE wopt.IsDeleted = 0 and wopt.MasterCompanyId= @MasterCompanyId and wo.IsDeleted = 0  and wopt.IsConfirmed=1 
							and wop.ID not in(SELECT WorkOrderPartNumId FROM DBO.WorkOrderShippingItem WOBI 
												WHERE WOBI.IsDeleted = 0) 

					GROUP BY wop.WorkOrderId,wo.WorkOrderNum,imt.partnumber,imt.PartDescription,wo.CustomerName,wo.customerId,P.Description,WOS.AirwayBill,
								wopt.ConfirmedDate,wos.AirwayBill,WOP.ID,wopt.PickTicketId,wos.WorkOrderShippingId,WOSI.QtyShipped,WOPSI.PackagingSlipId

					UNION

					SELECT  SOP.SalesOrderId as RefId,
							SO.SalesOrderNumber as RefNumber,	
							ITM.partnumber,
							ITM.PartDescription,
							SO.CustomerName as Customer,
							SO.CustomerId as CustomerId,
							P.Description as Priority,
							'Ready to ship' AS 'Status',	
							cast(sopt.ConfirmedDate as date) AS ShipDate,
							'' as ShipVia,
							SOS.AirwayBill AS AWB,
							'SO' as ModuleName,
							SOP.SalesOrderPartId as PartId,
							SOPT.SOPickTicketId as PickTicketId,
							sos.SalesOrderShippingId as ShippingId,
							SUM(ISNULL(SOSI.QtyShipped,0)) AS QtyShipped,
							SOPSI.PackagingSlipId AS PackagingSlipId,
							0 AS VendorRMADetailId

					FROM DBO.SalesOrderPart sop WITH (NOLOCK)
						LEFT JOIN DBO.SalesOrder so WITH (NOLOCK) ON so.SalesOrderId = sop.SalesOrderId
						LEFT JOIN DBO.SalesOrderShipping SOS WITH (NOLOCK) ON SOS.SalesOrderId = SO.SalesOrderId
						INNER JOIN DBO.SOPickTicket sopt WITH (NOLOCK) ON sopt.SalesOrderId = sop.SalesOrderId AND sopt.SalesOrderPartId = sop.SalesOrderPartId
						LEFT JOIN SalesOrderShippingItem SOSI WITH (NOLOCK) ON SOSI.SalesOrderShippingId = SOS.SalesOrderShippingId and sosi.SOPickTicketId = sopt.SOPickTicketId
						LEFT JOIN SalesOrderPackaginSlipItems SOPSI WITH (NOLOCK) ON SOPSI.SalesOrderPartId = SOP.SalesOrderPartId and SOPSI.SOPickTicketId = sopt.SOPickTicketId					
						LEFT JOIN DBO.ItemMaster ITM WITH (NOLOCK) ON ITM.ItemMasterId = sop.ItemMasterId
						LEFT JOIN DBO.Priority P WITH (NOLOCK)  ON P.PriorityId = sop.PriorityId
						LEFT JOIN DBO.CustomerDomensticShippingShipVia SV WITH (NOLOCK)  ON SV.CustomerId = so.CustomerId and SV.IsPrimary=1

					WHERE  sopt.IsDeleted = 0 and sopt.MasterCompanyId= @MasterCompanyId AND sopt.IsConfirmed = 1
							and sop.SalesOrderPartId not in(SELECT SalesOrderPartId FROM DBO.SalesOrderShippingItem SOSI 
											WHERE SOSI.IsDeleted = 0)
						
					GROUP BY SOP.SalesOrderId,SO.SalesOrderNumber,ITM.partnumber,ITM.PartDescription,SO.CustomerName,SO.CustomerId,P.Description,SOS.AirwayBill,
								sopt.ConfirmedDate,SOS.AirwayBill,SOP.SalesOrderPartId,SOPT.SOPickTicketId, SO.customerId, sos.SalesOrderShippingId,SOSI.QtyShipped,SOPSI.PackagingSlipId
				
					UNION

					SELECT sop.ExchangeSalesOrderId as RefId,
								so.ExchangeSalesOrderNumber as RefNumber,
								ITM.partnumber,
								ITM.PartDescription,
								so.CustomerName as Customer,
								so.CustomerId as CustomerId,
								P.Description as Priority,
								'Ready to ship' AS 'Status',	
								cast(sopt.ConfirmedDate as date) AS ShipDate,
								'' as ShipVia,
								SOS.AirwayBill AS AWB,
								'ESO' AS 'ModuleName',
								sop.ExchangeSalesOrderPartId as PartId,
								SOPT.SOPickTicketId as PickTicketId,
								sos.ExchangeSalesOrderShippingId as ShippingId,
								SOSI.QtyShipped AS QtyShipped,
								SOPSI.PackagingSlipId AS PackagingSlipId,
								0 AS VendorRMADetailId
						
					FROM DBO.ExchangeSalesOrderPart sop WITH (NOLOCK)
							LEFT JOIN DBO.ExchangeSalesOrder so WITH (NOLOCK) on so.ExchangeSalesOrderId = sop.ExchangeSalesOrderId
							LEFT JOIN DBO.ExchangeSalesOrderShipping SOS WITH (NOLOCK) ON SOS.ExchangeSalesOrderId = SO.ExchangeSalesOrderId
							INNER JOIN DBO.ExchangeSOPickTicket sopt WITH (NOLOCK) on sopt.ExchangeSalesOrderId = sop.ExchangeSalesOrderId AND sopt.ExchangeSalesOrderPartId = sop.ExchangeSalesOrderPartId
							LEFT JOIN DBO.ItemMaster ITM WITH (NOLOCK) on ITM.ItemMasterId = sop.ItemMasterId
							LEFT JOIN DBO.Priority P WITH (NOLOCK)  ON P.PriorityId = sop.PriorityId
							LEFT JOIN ExchangeSalesOrderShippingItem SOSI WITH (NOLOCK) ON SOSI.ExchangeSalesOrderShippingId = SOS.ExchangeSalesOrderShippingId AND sosi.SOPickTicketId = sopt.SOPickTicketId
							LEFT JOIN ExchangeSalesOrderPackaginSlipItems SOPSI WITH (NOLOCK) ON SOPSI.ExchangeSalesOrderPartId = SOP.ExchangeSalesOrderPartId and SOPSI.SOPickTicketId = sopt.SOPickTicketId
							LEFT JOIN DBO.CustomerDomensticShippingShipVia SV WITH (NOLOCK)  ON SV.CustomerId = so.CustomerId and SV.IsPrimary=1

					WHERE  sopt.IsDeleted = 0 and sopt.MasterCompanyId= @MasterCompanyId  and so.IsDeleted = 0  and sopt.IsConfirmed = 1
							and sop.ExchangeSalesOrderPartId not in(SELECT ExchangeSalesOrderPartId FROM DBO.ExchangeSalesOrderShippingItem ESOSI 
										WHERE ESOSI.IsDeleted = 0) 

					GROUP BY sop.ExchangeSalesOrderId,so.ExchangeSalesOrderNumber,ITM.partnumber,ITM.PartDescription,so.CustomerName,so.customerId,P.Description,SOS.AirwayBill,
								sopt.ConfirmedDate,SOS.AirwayBill,sop.ExchangeSalesOrderPartId,SOPT.SOPickTicketId,sos.ExchangeSalesOrderShippingId,SOSI.QtyShipped,SOPSI.PackagingSlipId
				
					UNION	

					SELECT VD.VendorRMAId as RefId,
							VR.RMANumber as RefNumber,
							IMT.partnumber,
							IMT.PartDescription,
							V.VendorName as Customer,
							v.VendorId as CustomerId,
							IMT.Priority as Priority,
							'Ready to ship' AS 'Status',
							cast(RPT.ConfirmedDate AS DATE) AS ShipDate,
							'' as ShipVia,
							RS.AirwayBill as AWB,
							'VENDOR RMA' AS ModuleName,
							IMT.ItemMasterId as PartId,
							RPT.RMAPickTicketId AS PickTicketId,
							RS.RMAShippingId AS ShippingId,
							RSI.QtyShipped AS QtyShipped,
							RPSI.PackagingSlipId AS PackagingSlipId,
							VD.VendorRMADetailId AS VendorRMADetailId


					FROM [dbo].[VendorRMADetail] VD WITH(NOLOCK) 
						  -- INNER JOIN [dbo].[Stockline] SL WITH (NOLOCK) ON VD.[StockLineId] = SL.[StockLineId]
						  INNER JOIN VendorRMA VR WITH (NOLOCK) ON VD.VendorRMAId = VR.VendorRMAId
						  INNER JOIN [dbo].[ItemMaster] IMT WITH (NOLOCK) ON VD.[ItemMasterId] = imt.[ItemMasterId]
						  LEFT JOIN RMAShipping RS WITH (NOLOCK) ON VD.VendorRMAId=RS.VendorRMAId
						  INNER JOIN Vendor V WITH (NOLOCK) ON VR.VENDORID = V.VendorId						 
						  LEFT JOIN RMAPickTicket RPT WITH (NOLOCK) ON VD.VendorRMADetailId = RPT.VendorRMADetailId
						  LEFT JOIN RMAShippingItem RSI WITH (NOLOCK) ON RSI.RMAShippingId=RS.RMAShippingId and RSI.RMAPickTicketId = RPT.RMAPickTicketId
						  LEFT JOIN VendorRMAPackaginSlipItems RPSI WITH (NOLOCK) ON RPSI.VendorRMADetailId = VD.VendorRMADetailId and RPSI.RMAPickTicketId = RPT.RMAPickTicketId
						  LEFT JOIN DBO.ShippingVia SV WITH (NOLOCK) ON SV.ShippingViaId = RS.ShipViaId -- and SV.IsPrimary=1

					 WHERE  RPT.IsDeleted = 0 and RPT.MasterCompanyId= @MasterCompanyId  and vr.IsDeleted = 0  and RPT.IsConfirmed = 1 AND  RS.AirwayBill IS NULL
								and RPT.RMAPickTicketId not in(SELECT RMAPickTicketId FROM DBO.RMAShippingItem RSI 
										WHERE RSI.IsDeleted = 0) 

					 GROUP BY VD.VendorRMAId,VR.RMANumber,IMT.partnumber,IMT.PartDescription,V.VendorName,v.VendorId,IMT.[Priority],RS.AirwayBill,RPT.ConfirmedDate,RS.AirwayBill,
								IMT.ItemMasterId , RPT.RMAPickTicketId , RS.RMAShippingId,RSI.QtyShipped ,RPSI.PackagingSlipId ,VD.VendorRMADetailId

						),
							FinalResult AS (

							SELECT RefId,RefNumber,PartNumber,PartDescription,Customer,CustomerId,[Priority],[Status],ShipVia,ShipDate,AWB,ModuleName,PartId,PickTicketId,ShippingId,QtyShipped,
										PackagingSlipId,VendorRMADetailId										
				
							FROM Result 
							where (
								(@GlobalFilter <> '' AND ((RefNumber like '%' + @GlobalFilter +'%') OR
										(PartNumber like '%' + @GlobalFilter +'%') OR
										(PartDescription like '%'+ @GlobalFilter +'%') OR
										(Customer like '%' + @GlobalFilter +'%') OR
										(CustomerId like '%' + @GlobalFilter +'%') OR
										(Priority like '%' + @GlobalFilter +'%') OR
										(Status like '%' + @GlobalFilter +'%')OR
										(ShipVia like '%' + @GlobalFilter +'%') OR
										-- (ShipDate like '%' + @GlobalFilter +'%') OR
										(AWB  LIKE '%' +@GlobalFilter+'%') 
										))
										OR   
										(@GlobalFilter = '' AND 
										(ISNULL(@RefNumber, '') = '' OR RefNumber like  '%'+ @RefNumber +'%') and
										(ISNULL(@PartNumber, '') = '' OR PartNumber like '%'+ @PartNumber +'%') and
										(ISNULL(@PartDescription, '') = '' OR PartDescription like '%'+ @PartDescription +'%') and
										(ISNULL(@Customer, '') = '' OR Customer like '%'+ @Customer +'%') and
										(ISNULL(@Priority, '') = '' OR [Priority] like '%'+ @Priority +'%') and
										(ISNULL(@Status,'') ='' OR [Status] like  '%'+@Status+'%') and
										(ISNULL(@ShipVia, '') = '' OR ShipVia like '%'+ @ShipVia +'%') and
										(ISNULL(@ShipDate, '') = '' OR cast(ShipDate as date) = cast(@ShipDate as date))  and
										(ISNULL(@AWB, '') = '' OR AWB like '%'+ @AWB+'%') 
										))),
								ResultCount AS (Select COUNT(RefId) AS NumberOfItems FROM FinalResult)


								SELECT RefId,RefNumber,PartNumber,PartDescription,Customer,CustomerId,[Priority],[Status],ShipVia,ShipDate,AWB,ModuleName,PartId,PickTicketId,ShippingId,QtyShipped,
										PackagingSlipId,VendorRMADetailId,NumberOfItems
					
								FROM FinalResult, ResultCount

								ORDER BY  
									CASE WHEN (@SortOrder=1 and @SortColumn='REFID')  THEN RefId END ASC,
									CASE WHEN (@SortOrder=1 and @SortColumn='RefNumber')  THEN RefNumber END ASC,
									CASE WHEN (@SortOrder=1 and @SortColumn='PARTNUMBER')  THEN PartNumber END ASC,
									CASE WHEN (@SortOrder=1 and @SortColumn='PARTDESCRIPTION')  THEN PartDescription END ASC,
									CASE WHEN (@SortOrder=1 and @SortColumn='Customer')  THEN Customer END ASC,
									CASE WHEN (@SortOrder=1 and @SortColumn='CustomerId')  THEN CustomerId END ASC,
									CASE WHEN (@SortOrder=1 and @SortColumn='PRIORITY')  THEN [Priority] END ASC,
									CASE WHEN (@SortOrder=1 and @SortColumn='Status')  THEN [Status] END ASC,
									CASE WHEN (@SortOrder=1 and @SortColumn='ShipVia')  THEN ShipVia END ASC,
									CASE WHEN (@SortOrder=1 and @SortColumn='ShipDate')  THEN ShipDate END ASC,
									CASE WHEN (@SortOrder=1 and @SortColumn='AWB')  THEN AWB END ASC,
									CASE WHEN (@SortOrder=1 and @SortColumn='ModuleName')  THEN ModuleName END ASC,
									CASE WHEN (@SortOrder=1 and @SortColumn='PartId')  THEN PartId END ASC,
									CASE WHEN (@SortOrder=1 and @SortColumn='PickTicketId')  THEN PickTicketId END ASC,
									CASE WHEN (@SortOrder=1 and @SortColumn='ShippingId')  THEN ShippingId END ASC,
				
									CASE WHEN (@SortOrder=-1 and @SortColumn='REFID')  THEN RefId END DESC,
									CASE WHEN (@SortOrder=-1 and @SortColumn='RefNumber')  THEN RefNumber END DESC,
									CASE WHEN (@SortOrder=-1 and @SortColumn='PARTNUMBER')  THEN PartNumber END DESC,
									CASE WHEN (@SortOrder=-1 and @SortColumn='PARTDESCRIPTION')  THEN PartDescription END DESC,
									CASE WHEN (@SortOrder=-1 and @SortColumn='Customer')  THEN Customer END DESC,
									CASE WHEN (@SortOrder=-1 and @SortColumn='CustomerId')  THEN CustomerId END DESC,
									CASE WHEN (@SortOrder=-1 and @SortColumn='PRIORITY')  THEN [Priority] END DESC,
									CASE WHEN (@SortOrder=-1 and @SortColumn='STATUS')  THEN [Status] END DESC,
									CASE WHEN (@SortOrder=-1 and @SortColumn='ShipVia')  THEN ShipVia END DESC,
									CASE WHEN (@SortOrder=-1 and @SortColumn='ShipDate')  THEN ShipDate END DESC,
									CASE WHEN (@SortOrder=-1 and @SortColumn='AWB')  THEN AWB END DESC,				
									CASE WHEN (@SortOrder=-1 and @SortColumn='ModuleName')  THEN ModuleName END DESC,
									CASE WHEN (@SortOrder=-1 and @SortColumn='PartId')  THEN PartId END DESC,
									CASE WHEN (@SortOrder=-1 and @SortColumn='PickTicketId')  THEN PickTicketId END DESC,
									CASE WHEN (@SortOrder=-1 and @SortColumn='ShippingId')  THEN ShippingId END DESC
								OFFSET @RecordFrom ROWS 
								FETCH NEXT @PageSize ROWS ONLY
					
				END
			END
		COMMIT TRANSACTION
	END TRY


	BEGIN CATCH      
		IF @@trancount > 0
			ROLLBACK TRAN;
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
        ,@AdhocComments VARCHAR(150) = 'SearchShippingListData' 
        ,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = '''
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
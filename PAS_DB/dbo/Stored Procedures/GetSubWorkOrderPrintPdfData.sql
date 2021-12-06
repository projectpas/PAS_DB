
/*************************************************************           
 ** File:   [GetSubWorkOrderPrintPdfData]           
 ** Author:   Subhash Saliya
 ** Description: This stored procedure is used Work order Print  Details    
 ** Purpose:         
 ** Date:   12/30/2020        
          
 ** PARAMETERS:           
 @UserType varchar(60)   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    06/02/2020   Subhash Saliya Created
     
--EXEC [GetSubWorkOrderPrintPdfData] 50,96
**************************************************************/

CREATE PROCEDURE [dbo].[GetSubWorkOrderPrintPdfData]
@subWorkOrderId bigint,
@subWOPartNoId bigint
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN  
				SELECT  wo.WorkOrderId, 
						wo.CustomerId, 
						wo.CustomerName,
						swo.SubWorkOrderId, 
						wop.Quantity, 
						swo.SubWorkOrderNo as QuoteNumber,
						null as qouteDate,
						'1' as NoofItem,
						wo.CreatedBy as Preparedby,
						'' as ronum,
						getdate() as DatePrinted,
						wo.CreatedDate as workreqDate,
						p.Description as Priority,
						case when wop.IsPMA=1 then 'Yes' else 'No' end as RestrictPMA,
						case when wop.IsDER=1 then 'Yes' else 'No' end as RestrictDER,
						'' as wty,
						'' as wtyCode,
						imt.partnumber as IncomingPN,
						--rimt.PartDescription as RevisedPN,
						'' as RevisedPN,
						imt.PartDescription as PNDesc,
						sl.SerialNumber as SerialNum,
						imt.ItemGroup as itemGroup,
						'' as ACTailNum,
						'' as TSN,
						'' as CSN,
						getdate()  as Recd_Date,
					    '' as Qte_Date,
						'' as Qte_Appvd_Date,
						wop.CustomerRequestDate as Req_d_Date,
						wop.EstimatedShipDate as Est_Ship_Date,
						el.firstName +' '+ el.LastName  as TechNum,
						ws.Stage as WOStage,
						wo.WorkOrderNum,
						billsitename =  billToSite.SiteName,
						billAddressLine1 =  billToAddress.Line1,
                        billAddressLine2 =  billToAddress.Line2,
                        billCity = billToAddress.City,
                        billState = billToAddress.StateOrProvince,
                        billPostalCode =billToAddress.PostalCode ,
						billCountry =  billToCountry.countries_name ,
						billAttention =  billToSite.Attention,
						shipSiteName =  shipToSite.SiteName,
                        shipAttention =  shipToSite.Attention,
						shipAddressLine1 = shipToAddress.Line1,
                        shipAddressLine2 = shipToAddress.Line2,
                        shipCity =  shipToAddress.City,
                        shipState =  shipToAddress.StateOrProvince,
                        shipPostalCode = shipToAddress.PostalCode,
                        shipCountry = shipToCountry.countries_name,
						ManagementStructureId = (select top 1 ManagementStructureId from WorkOrderPartNumber WITH(NOLOCK) where WorkOrderId=wo.WorkOrderId),
						wop.WorkflowId as WorkFlowWorkOrderId,
						swo.UpdatedDate
				FROM Dbo.SubWorkOrder swo WITH(NOLOCK)
					INNER JOIN Dbo.SubWorkOrderPartNumber wop WITH(NOLOCK) on wop.SubWorkOrderId = swo.SubWorkOrderId --AND wop.ID = wopt.OrderPartId
					inner join Dbo.WorkOrder wo WITH(NOLOCK) on wo.WorkOrderId= swo.WorkOrderId
					LEFT JOIN Dbo.Customer billToCustomer WITH(NOLOCK) on wo.CustomerId = billToCustomer.CustomerId
					LEFT JOIN Dbo.CustomerBillingAddress  billToSite WITH(NOLOCK) on wo.CustomerId = billToSite.CustomerId and billToSite.IsPrimary=1
					LEFT JOIN Dbo.Address billToAddress WITH(NOLOCK) on billToSite.AddressId = billToAddress.AddressId
					left JOIN Dbo.Countries billToCountry WITH(NOLOCK) on billToCountry.countries_id = billToAddress.CountryId
					LEFT JOIN Dbo.CustomerDomensticShipping shipToSite WITH(NOLOCK) on wo.CustomerId = shipToSite.CustomerId and shipToSite.IsPrimary=1
					LEFT JOIN Dbo.Address shipToAddress WITH(NOLOCK) on shipToSite.AddressId = shipToAddress.AddressId
					LEFT JOIN Dbo.Countries shipToCountry WITH(NOLOCK) on shipToAddress.CountryId = shipToCountry.countries_id
					LEFT JOIN Dbo.ItemMaster imt WITH(NOLOCK) on imt.ItemMasterId = wop.ItemMasterId
					LEFT JOIN Dbo.Priority p  WITH(NOLOCK) on p.PriorityId = wop.SubWorkOrderPriorityId
					LEFT JOIN Dbo.WorkOrderStage ws WITH(NOLOCK) on ws.WorkOrderStageId = wop.SubWorkOrderStageId
					LEFT JOIN Dbo.Stockline sl WITH(NOLOCK) on sl.StockLineId = wop.StockLineId
					LEFT JOIN Dbo.Employee el WITH(NOLOCK) on el.EmployeeId = wop.TechnicianId
				WHERE swo.SubWorkOrderId = @subWorkOrderId AND wop.SubWOPartNoId = @subWOPartNoId
		END
		COMMIT  TRANSACTION
		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'GetSubWorkOrderPrintPdfData' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@subWorkOrderId, '') + '''
													   @Parameter2 = ' + ISNULL(@subWOPartNoId ,'') +''
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
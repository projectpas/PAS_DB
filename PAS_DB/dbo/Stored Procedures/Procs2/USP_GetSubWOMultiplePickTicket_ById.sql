Create   PROCEDURE [dbo].[USP_GetSubWOMultiplePickTicket_ById]
@WorkOrderId bigint,
@SubWorkOrderId bigint
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN 
				
				SELECT DISTINCT
					max(swo.WorkOrderId) as WorkOrderId,
					max(swo.SubWorkOrderId) as SubWorkOrderId,
					max(swop.PickTicketId) as PickTicketId,
					swop.PickTicketNumber as PickTicketNumber,
					max(wo.WorkOrderNum) as WorkOrderNum,
					max(swo.SubWorkOrderNo) as SubWorkOrderNum,
					max(wo.CustomerId) as CustomerId,
					max(cu.Name) as 'CustomerName',
					max(cu.CustomerCode) as CustomerCode,
					max(a.Line1) as 'CustToAddress1',
					max(a.Line2) as 'CustToAddress2',
					max(a.City) as 'CustToCity',
					max(a.StateOrProvince) as 'CustToState',
					max(a.PostalCode) as 'CustToPostalCode',
					max(c.countries_name) as 'CustToCountry',
					max(ca.FirstName + ' ' + ca.LastName) as 'CustomerContactName',
					max(cds.SiteName) as 'ShipToSiteName',
					max(ad.Line1) as 'ShipToAddress1',
					max(ad.Line2) as 'ShipToAddress2',
					max(ad.City) as 'ShipToCity',
					max(ad.StateOrProvince) as 'ShipToState',
					max(ad.PostalCode) as 'ShipToPostalCode',
					max(co.countries_name) as 'ShipToCountry',
					max(' ') as 'ShipToContactName',
					ISNULL(max(als.ShipVia),'-') as 'ShipViaName',
					max(wo.CreatedBy) as 'CreatedBy',
					max(wo.CreatedDate) as 'CreatedDate',
					max(wo.UpdatedBy) as 'UpdatedBy',
					max(wo.UpdatedDate) as 'UpdatedDate',
					max(e.FirstName + ' ' + e.LastName) as 'PickedByName',
					max(swop.CreatedDate) 'PickedDate',
					max(em.FirstName + ' ' + em.LastName) as 'ConfirmedByName',
					max(swop.ConfirmedDate) as 'ConfirmedDate',
					max(swop.CreatedDate) as 'PTCreatedDate',
					max(stk.ManagementStructureId) as ManagementStructureId,
					max(swop.PDFPath) as PDFPath
				FROM [DBO].[WorkOrder] wo WITH (NOLOCK) 
				LEFT JOIN [DBO].[SubWorkOrder] swo ON wo.WorkOrderId = swo.WorkOrderId
				LEFT JOIN [DBO].[SubWorkOrderPartNumber] swopn ON swo.SubWorkOrderId  = swopn.SubWorkOrderId
				LEFT JOIN [DBO].[StockLine] stk on swopn.StockLineId  = stk.StockLineId
				LEFT JOIN [DBO].[SubWorkorderPickTicket] swop ON swopn.SubWOPartNoId = swop.SubWorkorderPartNoId
				LEFT JOIN [DBO].[CustomerDomensticShipping] cds ON wo.CustomerId = cds.CustomerId and cds.IsPrimary = 1 
				LEFT JOIN [DBO].[Address] a ON cds.AddressId = a.AddressId
				LEFT JOIN [DBO].[Countries] c ON a.CountryId = c.countries_id
				LEFT JOIN [DBO].[Customer] cu ON wo.CustomerId = cu.CustomerId
				LEFT JOIN [DBO].[Address] ad ON cu.AddressId = ad.AddressId
				LEFT JOIN [DBO].[Countries] co ON ad.CountryId =  co.countries_id
				LEFT JOIN [DBO].[CustomerContact] cc ON  wo.CustomerContactId = cc.CustomerContactId
				LEFT JOIN [DBO].[Contact] ca ON cc.ContactId = ca.ContactId
				LEFT JOIN [DBO].[CustomerDomensticShippingShipVia] cdssv ON wo.CustomerId = cdssv.CustomerId AND cdssv.IsPrimary = 1
				LEFT JOIN [DBO].[AllShipVia] als ON cdssv.ShipViaId = als.ShipViaId
				LEFT JOIN [DBO].[Employee] e ON swop.PickedById = e.EmployeeId
				LEFT JOIN [DBO].[Employee] em ON swop.ConfirmedById = em.EmployeeId
				
				WHERE swop.[WorkOrderId] = @WorkOrderId and swop.[SubWorkorderId] = @SubWorkOrderId GROUP BY swop.PickTicketNumber
			END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				--PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetSubWOMultiplePickTicket_ById' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@WorkOrderId, '') + '@Parameter2 = '''+ ISNULL(@SubWorkOrderId, '') + ''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

              exec spLogException 
                       @DatabaseName			= @DatabaseName
                     , @AdhocComments			= @AdhocComments
                     , @ProcedureParameters		= @ProcedureParameters
                     , @ApplicationName         = @ApplicationName
                     , @ErrorLogID              = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
		END CATCH
END
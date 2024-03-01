
/*************************************************************           
 ** File:   [USP_GetMultiplePickTicket_ById]           
 ** Author:   Vishal Suthar
 ** Description: This stored procedure is used get data for multiple pick tickets   
 ** Purpose:
 ** Date:   
          
 ** PARAMETERS:           
         
 ** RETURN VALUE:           

 **************************************************************           
 ** Change History           
 **************************************************************           
 PR   Date         Author			Change Description            
 --   --------     -------			--------------------------------          
  1   06/29/2023   Vishal Suthar	Modified to fix the issue of duplicate pick tickets in case of KIT and Non-kit Parts are there

--  EXEC [USP_GetMultiplePickTicket_ById] 3109
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetMultiplePickTicket_ById]
	@WorkFlowWorkOrderId bigint
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN 
				IF OBJECT_ID(N'tempdb..#tmpPickTicket') IS NOT NULL
				BEGIN
					DROP TABLE #tmpPickTicket
				END

				CREATE TABLE #tmpPickTicket 
				(
					ID BIGINT NOT NULL IDENTITY, 
					[WorkFlowWorkOrderId] [bigint] NULL,
					[WorkOrderId] [bigint] NULL,
					[WorkOrderMaterialsId] [bigint] NULL,
					[PickTicketId] [bigint] NULL,
					[PickTicketNumber] VARCHAR(50) NULL,
					[WorkOrderNum] VARCHAR(30) NULL,
					[CustomerId] [bigint] NULL,
					[CustomerName] VARCHAR(100) NULL,
					[CustomerCode] VARCHAR(100) NULL,
					[CustToAddress1] VARCHAR(50) NULL,
					[CustToAddress2] VARCHAR(50) NULL,
					[CustToCity] VARCHAR(50) NULL,
					[CustToState] VARCHAR(50) NULL,
					[CustToPostalCode] VARCHAR(50) NULL,
					[CustToCountry] VARCHAR(100) NULL,
					[CustomerContactName] VARCHAR(100) NULL,
					[ShipToSiteName] VARCHAR(50) NULL,
					[ShipToAddress1] VARCHAR(100) NULL,
					[ShipToAddress2] VARCHAR(100) NULL,
					[ShipToCity] VARCHAR(50) NULL,
					[ShipToState] VARCHAR(50) NULL,
					[ShipToPostalCode] VARCHAR(50) NULL,
					[ShipToCountry] VARCHAR(50) NULL,
					[ShipToContactName] VARCHAR(100) NULL,
					[ShipViaName] VARCHAR(100) NULL,
					[CreatedBy] VARCHAR(100) NULL,
					[CreatedDate] DATETIME2(7) NULL,
					[UpdatedBy] VARCHAR(100) NULL,
					[UpdatedDate] DATETIME2(7) NULL,
					[PickedByName] VARCHAR(100) NULL,
					[PickedDate] DATETIME2(7) NULL,
					[ConfirmedByName] VARCHAR(100) NULL,
					[ConfirmedDate] DATETIME2(7) NULL,
					[PTCreatedDate] DATETIME2(7) NULL,
					[ManagementStructureId] [bigint] NULL,
					[PDFPath] VARCHAR(500) NULL
				)

				INSERT INTO #tmpPickTicket ([WorkFlowWorkOrderId],[WorkOrderId],[WorkOrderMaterialsId],[PickTicketId],[PickTicketNumber],[WorkOrderNum],[CustomerId],[CustomerName],
				[CustomerCode],[CustToAddress1],[CustToAddress2],[CustToCity],[CustToState],[CustToPostalCode],[CustToCountry],[CustomerContactName],[ShipToSiteName],[ShipToAddress1],
				[ShipToAddress2],[ShipToCity],[ShipToState],[ShipToPostalCode],[ShipToCountry],[ShipToContactName],[ShipViaName],[CreatedBy],[CreatedDate],[UpdatedBy],[UpdatedDate],
				[PickedByName],[PickedDate],[ConfirmedByName],[ConfirmedDate],[PTCreatedDate],[ManagementStructureId],[PDFPath])
				(SELECT DISTINCT
					max(wom.WorkFlowWorkOrderId) as WorkFlowWorkOrderId,
					max(wom.WorkOrderId) as WorkOrderId,
					max(wom.WorkOrderMaterialsId) as WorkOrderMaterialsId,
					max(wop.PickTicketId) as PickTicketId,
					wop.PickTicketNumber as PickTicketNumber,
					max(wo.WorkOrderNum) as WorkOrderNum,
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
					max(als.ShipVia) as 'ShipViaName',
					max(wo.CreatedBy) as 'CreatedBy',
					max(wo.CreatedDate) as 'CreatedDate',
					max(wo.UpdatedBy) as 'UpdatedBy',
					max(wo.UpdatedDate) as 'UpdatedDate',
					max(e.FirstName + ' ' + e.LastName) as 'PickedByName',
					max(wop.CreatedDate) 'PickedDate',
					max(em.FirstName + ' ' + em.LastName) as 'ConfirmedByName',
					max(wop.ConfirmedDate) as 'ConfirmedDate',
					max(wop.CreatedDate) as 'PTCreatedDate',
					max(wopn.ManagementStructureId) as ManagementStructureId,
					max(wop.PDFPath) as PDFPath
				FROM [DBO].[WorkOrderMaterials] wom WITH (NOLOCK) 
				JOIN [DBO].[WorkorderPickTicket] wop ON wom.WorkOrderMaterialsId = wop.WorkOrderMaterialsId
				JOIN [DBO].[WorkOrderWorkFlow] wowf ON wom.WorkFlowWorkOrderId  = wowf.WorkFlowWorkOrderId
				JOIN [DBO].[WorkOrderPartNumber] wopn ON wopn.ID  = wowf.WorkOrderPartNoId
				JOIN [DBO].[WorkOrder] wo ON wopn.WorkOrderId = wo.WorkOrderId
				JOIN [DBO].[Customer] cu ON wo.CustomerId = cu.CustomerId
				LEFT JOIN [DBO].[CustomerDomensticShipping] cds ON wo.CustomerId = cds.CustomerId and cds.IsPrimary = 1 
				LEFT JOIN [DBO].[Address] a ON cds.AddressId = a.AddressId
				LEFT JOIN [DBO].[Countries] c ON a.CountryId = c.countries_id				
				LEFT JOIN [DBO].[Address] ad ON cu.AddressId = ad.AddressId
				LEFT JOIN [DBO].[Countries] co ON ad.CountryId =  co.countries_id
				LEFT JOIN [DBO].[CustomerContact] cc ON  wo.CustomerContactId = cc.CustomerContactId
				LEFT JOIN [DBO].[Contact] ca ON cc.ContactId = ca.ContactId
				LEFT JOIN [DBO].[CustomerDomensticShippingShipVia] cdssv ON wo.CustomerId = cdssv.CustomerId AND cdssv.IsPrimary = 1
				LEFT JOIN [DBO].[AllShipVia] als ON cdssv.ShipViaId = als.ShipViaId
				LEFT JOIN [DBO].[Employee] e ON wop.PickedById = e.EmployeeId
				LEFT JOIN [DBO].[Employee] em ON wop.ConfirmedById = em.EmployeeId
				WHERE wom.[WorkFlowWorkOrderId] = @WorkFlowWorkOrderId  GROUP BY wop.PickTicketNumber

				UNION ALL

				SELECT DISTINCT
					max(wom.WorkFlowWorkOrderId) as WorkFlowWorkOrderId,
					max(wom.WorkOrderId) as WorkOrderId,
					max(wom.WorkOrderMaterialsKitId) as WorkOrderMaterialsId,
					max(wop.PickTicketId) as PickTicketId,
					wop.PickTicketNumber as PickTicketNumber,
					max(wo.WorkOrderNum) as WorkOrderNum,
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
					max(als.ShipVia) as 'ShipViaName',
					max(wo.CreatedBy) as 'CreatedBy',
					max(wo.CreatedDate) as 'CreatedDate',
					max(wo.UpdatedBy) as 'UpdatedBy',
					max(wo.UpdatedDate) as 'UpdatedDate',
					max(e.FirstName + ' ' + e.LastName) as 'PickedByName',
					max(wop.CreatedDate) 'PickedDate',
					max(em.FirstName + ' ' + em.LastName) as 'ConfirmedByName',
					max(wop.ConfirmedDate) as 'ConfirmedDate',
					max(wop.CreatedDate) as 'PTCreatedDate',
					max(wopn.ManagementStructureId) as ManagementStructureId,
					max(wop.PDFPath) as PDFPath
				FROM [DBO].[WorkOrderMaterialsKit] wom WITH (NOLOCK) 
				JOIN [DBO].[WorkorderPickTicket] wop ON wom.WorkOrderMaterialsKitId = wop.WorkOrderMaterialsId AND ISNULL(wop.IsKitType, 0) = 1
				JOIN [DBO].[WorkOrderWorkFlow] wowf ON wom.WorkFlowWorkOrderId  = wowf.WorkFlowWorkOrderId
				JOIN [DBO].[WorkOrderPartNumber] wopn ON wopn.ID  = wowf.WorkOrderPartNoId
				JOIN [DBO].[WorkOrder] wo ON wopn.WorkOrderId = wo.WorkOrderId
				JOIN [DBO].[Customer] cu ON wo.CustomerId = cu.CustomerId
				LEFT JOIN [DBO].[CustomerDomensticShipping] cds ON wo.CustomerId = cds.CustomerId and cds.IsPrimary = 1 
				LEFT JOIN [DBO].[Address] a ON cds.AddressId = a.AddressId
				LEFT JOIN [DBO].[Countries] c ON a.CountryId = c.countries_id
				LEFT JOIN [DBO].[Address] ad ON cu.AddressId = ad.AddressId
				LEFT JOIN [DBO].[Countries] co ON ad.CountryId =  co.countries_id
				LEFT JOIN [DBO].[CustomerContact] cc ON  wo.CustomerContactId = cc.CustomerContactId
				LEFT JOIN [DBO].[Contact] ca ON cc.ContactId = ca.ContactId
				LEFT JOIN [DBO].[CustomerDomensticShippingShipVia] cdssv ON wo.CustomerId = cdssv.CustomerId AND cdssv.IsPrimary = 1
				LEFT JOIN [DBO].[AllShipVia] als ON cdssv.ShipViaId = als.ShipViaId
				LEFT JOIN [DBO].[Employee] e ON wop.PickedById = e.EmployeeId
				LEFT JOIN [DBO].[Employee] em ON wop.ConfirmedById = em.EmployeeId
				
				WHERE wom.[WorkFlowWorkOrderId] = @WorkFlowWorkOrderId  GROUP BY wop.PickTicketNumber)
			END

			SELECT DISTINCT 
					max(WorkFlowWorkOrderId) as WorkFlowWorkOrderId,
					max(WorkOrderId) as WorkOrderId,
					max(WorkOrderMaterialsId) as WorkOrderMaterialsId,
					max(PickTicketId) as PickTicketId,
					PickTicketNumber as PickTicketNumber,
					max(WorkOrderNum) as WorkOrderNum,
					max(CustomerId) as CustomerId,
					max(CustomerName) as 'CustomerName',
					max(CustomerCode) as CustomerCode,
					max(CustToAddress1) as 'CustToAddress1',
					max(CustToAddress2) as 'CustToAddress2',
					max(CustToCity) as 'CustToCity',
					max(CustToState) as 'CustToState',
					max(CustToPostalCode) as 'CustToPostalCode',
					max(CustToCountry) as 'CustToCountry',
					max(CustomerContactName) as 'CustomerContactName',
					max(ShipToSiteName) as 'ShipToSiteName',
					max(ShipToAddress1) as 'ShipToAddress1',
					max(ShipToAddress2) as 'ShipToAddress2',
					max(ShipToCity) as 'ShipToCity',
					max(ShipToState) as 'ShipToState',
					max(ShipToPostalCode) as 'ShipToPostalCode',
					max(ShipToCountry) as 'ShipToCountry',
					max(ShipToContactName) as 'ShipToContactName',
					max(ShipViaName) as 'ShipViaName',
					max(CreatedBy) as 'CreatedBy',
					max(CreatedDate) as 'CreatedDate',
					max(UpdatedBy) as 'UpdatedBy',
					max(UpdatedDate) as 'UpdatedDate',
					max(PickedByName) as 'PickedByName',
					max(PickedDate) 'PickedDate',
					max(ConfirmedByName) as 'ConfirmedByName',
					max(ConfirmedDate) as 'ConfirmedDate',
					max(PTCreatedDate) as 'PTCreatedDate',
					max(ManagementStructureId) as ManagementStructureId,
					max(PDFPath) as PDFPath 
			FROM #tmpPickTicket GROUP BY PickTicketNumber;

		COMMIT  TRANSACTION
		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetMultiplePickTicket_ById' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@WorkFlowWorkOrderId, '') + ''
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
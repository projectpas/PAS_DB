/*************************************************************           
 ** File:   [GetSalesOrderChargesBySOId]           
 ** Author:   Abhishek Jirawla
 ** Description: Get Sales Order Confirmation list By SOId
 ** Purpose:         
 ** Date:   08-APR-2025  
         
 ** RETURN VALUE: 
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date			Author			Change Description            
 ** --   --------		-------			--------------------------------          
    1    08-APR-2025   Abhishek Jirawla Created
	2    26-12-2025    Nakul Chandigra  removed Formate from the Opendate 
     
 EXECUTE [GetSOConfirmationListExport] 1, pnview
**************************************************************/ 
CREATE   PROCEDURE [dbo].[GetSOConfirmationListExport]
    @MasterCompanyId INT,
	@ListViewType VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
	BEGIN TRY
		DECLARE @ApprovedStatus INT
		SELECT @ApprovedStatus = Id FROM dbo.MasterSalesOrderStatus WITH (NOLOCK) WHERE Name = 'Approved'
		DECLARE @PnView VARCHAR(20) = 'pnview', @SoView VARCHAR(20) = 'soview'

		IF @ListViewType = @PnView -- PN View
		BEGIN
			SELECT 
				part.SalesOrderId AS SOConformationNumber,
				part.SalesOrderId,
				part.SalesOrderPartId,
				soqp.SalesOrderQuoteId,
				part.ItemMasterId,
				sops.StockLineId,
				so.SalesOrderNumber,
				ISNULL(q.SalesOrderQuoteNumber, '') AS SalesOrderQuoteNumber,
				so.OpenDate,
				ISNULL(cust.Name, '') AS CustomerName,
				ISNULL(qs.StockLineNumber, '') AS StockLineNumber,
				part.FxRate,
				part.QtyOrder AS Qty,
				part.CreatedBy,
				part.CreatedDate,
				part.UpdatedBy,
				part.UpdatedDate,
				itemMaster.PartNumber,
				itemMaster.PartDescription,
				CASE 
					WHEN qs.StockLineId IS NULL THEN 0
					WHEN qs.IsSerialized IS NULL THEN 0
					ELSE qs.IsSerialized 
				END AS IsSerialized,
				ISNULL(qs.SerialNumber, '') AS SerialNumber,
				ISNULL(qs.ControlNumber, '') AS ControlNumber,
				ISNULL(cp.Description, '') AS ConditionDescription,
				ISNULL(iu.ShortName, '') AS UOM,
				ISNULL(rPart.QtyToReserve, 0) AS QtyReserved,
				CASE 
					WHEN soc.CustomerStatusId = @ApprovedStatus THEN 1
					ELSE 0
				END AS IsApproved,
				ISNULL(so.CustomerReference, '') AS CustomerReference,
				ISNULL(st.Name, '') AS StatusName,
				LTRIM(RTRIM(ISNULL(con.FirstName, '') + ' ' + ISNULL(con.LastName, ''))) AS ConfirmedBy,
				ISNULL(soc.CustomerMemo, '') AS CustomerMemo,
				ISNULL(soc.InternalMemo, '') AS InternalMemo

			FROM dbo.SalesOrderPartV1 part WITH (NOLOCK)
			LEFT JOIN dbo.SalesOrderStockLineV1 sops WITH (NOLOCK) 
				ON part.SalesOrderPartId = sops.SalesOrderPartId
			LEFT JOIN dbo.SalesOrderApproval soc WITH (NOLOCK) 
				ON part.SalesOrderPartId = soc.SalesOrderPartId
			INNER JOIN dbo.SalesOrder so WITH (NOLOCK) 
				ON part.SalesOrderId = so.SalesOrderId
			LEFT JOIN dbo.Customer cust WITH (NOLOCK) 
				ON so.CustomerId = cust.CustomerId
			LEFT JOIN dbo.StockLine qs WITH (NOLOCK) 
				ON sops.StockLineId = qs.StockLineId
			INNER JOIN dbo.ItemMaster itemMaster WITH (NOLOCK) 
				ON part.ItemMasterId = itemMaster.ItemMasterId
			LEFT JOIN dbo.Condition cp WITH (NOLOCK) 
				ON part.ConditionId = cp.ConditionId
			LEFT JOIN dbo.SalesOrderQuotePartV1 soqp WITH (NOLOCK) 
				ON part.SalesOrderQuotePartId = soqp.SalesOrderQuotePartId
			LEFT JOIN dbo.SalesOrderQuote q WITH (NOLOCK) 
				ON soqp.SalesOrderQuoteId = q.SalesOrderQuoteId
			LEFT JOIN dbo.UnitOfMeasure iu WITH (NOLOCK) 
				ON itemMaster.ConsumeUnitOfMeasureId = iu.UnitOfMeasureId
			LEFT JOIN dbo.SalesOrderReserveParts rPart WITH (NOLOCK) 
				ON part.SalesOrderPartId = rPart.SalesOrderPartId
			LEFT JOIN dbo.UnitOfMeasure um WITH (NOLOCK) 
				ON itemMaster.PurchaseUnitOfMeasureId = um.UnitOfMeasureId
			LEFT JOIN dbo.MasterSalesOrderQuoteStatus st WITH (NOLOCK) 
				ON part.StatusId = st.Id
			LEFT JOIN dbo.Contact con WITH (NOLOCK) 
				ON soc.CustomerApprovedById = con.ContactId

			WHERE part.IsDeleted = 0
			  AND part.MasterCompanyId = @MasterCompanyId
		END
		ELSE IF @ListViewType = @SoView -- SO View
		BEGIN
			SELECT 
				part.SalesOrderId AS SOConformationNumber,
				part.SalesOrderId,
				part.SalesOrderPartId,
				soqp.SalesOrderQuoteId,
				part.ItemMasterId,
				sops.StockLineId,
				so.SalesOrderNumber,
				ISNULL(q.SalesOrderQuoteNumber, '') AS SalesOrderQuoteNumber,
				FORMAT(so.OpenDate, 'M/d/yyyy') AS OpenDate,
				ISNULL(cust.Name, '') AS CustomerName,
				ISNULL(qs.StockLineNumber, '') AS StockLineNumber,
				part.FxRate,
				part.QtyOrder AS Qty,
				part.CreatedBy,
				part.CreatedDate,
				part.UpdatedBy,
				part.UpdatedDate,
				itemMaster.PartNumber,
				itemMaster.PartDescription,
				qs.IsSerialized,
				ISNULL(qs.SerialNumber, '') AS SerialNumber,
				ISNULL(qs.ControlNumber, '') AS ControlNumber,
				ISNULL(cp.Description, '') AS ConditionDescription,
				ISNULL(iu.ShortName, '') AS UOM,
				rPart.QtyToReserve AS QtyReserved,
				CASE 
					WHEN soc.CustomerStatusId = @ApprovedStatus THEN 1
					ELSE 0
				END AS IsApproved,
				ISNULL(so.CustomerReference, '') AS CustomerReference,
				ISNULL(st.Name, '') AS StatusName,
				ISNULL(con.FirstName, '') + ' ' + ISNULL(con.LastName, '') AS ConfirmedBy,
				ISNULL(soc.CustomerMemo, '') AS CustomerMemo,
				ISNULL(soc.InternalMemo, '') AS InternalMemo

			FROM dbo.SalesOrderPartV1 part WITH (NOLOCK)
			LEFT JOIN dbo.SalesOrderStockLineV1 sops WITH (NOLOCK) ON part.SalesOrderPartId = sops.SalesOrderPartId
			LEFT JOIN dbo.SalesOrderApproval soc WITH (NOLOCK) ON part.SalesOrderPartId = soc.SalesOrderPartId
			INNER JOIN dbo.SalesOrder so WITH (NOLOCK) ON part.SalesOrderId = so.SalesOrderId
			LEFT JOIN dbo.Customer cust WITH (NOLOCK) ON so.CustomerId = cust.CustomerId
			LEFT JOIN dbo.StockLine qs WITH (NOLOCK) ON sops.StockLineId = qs.StockLineId
			INNER JOIN dbo.ItemMaster itemMaster WITH (NOLOCK) ON part.ItemMasterId = itemMaster.ItemMasterId
			LEFT JOIN dbo.Condition cp WITH (NOLOCK) ON part.ConditionId = cp.ConditionId
			LEFT JOIN dbo.SalesOrderQuotePartV1 soqp WITH (NOLOCK) ON part.SalesOrderQuotePartId = soqp.SalesOrderQuotePartId
			LEFT JOIN dbo.SalesOrderQuote q WITH (NOLOCK) ON soqp.SalesOrderQuoteId = q.SalesOrderQuoteId
			LEFT JOIN dbo.UnitOfMeasure iu WITH (NOLOCK) ON itemMaster.ConsumeUnitOfMeasureId = iu.UnitOfMeasureId
			LEFT JOIN dbo.SalesOrderReserveParts rPart WITH (NOLOCK) ON part.SalesOrderPartId = rPart.SalesOrderPartId
			LEFT JOIN dbo.UnitOfMeasure um WITH (NOLOCK) ON itemMaster.PurchaseUnitOfMeasureId = um.UnitOfMeasureId
			LEFT JOIN dbo.MasterSalesOrderQuoteStatus st WITH (NOLOCK) ON part.StatusId = st.Id
			LEFT JOIN dbo.Contact con WITH (NOLOCK) ON soc.CustomerApprovedById = con.ContactId

			WHERE part.IsDeleted = 0
			  AND part.MasterCompanyId = @MasterCompanyId
		END

		

	END TRY    
	BEGIN CATCH      

		DECLARE @ErrorLogID INT
			,@DatabaseName VARCHAR(100) = db_name()
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			,@AdhocComments VARCHAR(150) = 'GetSalesOrderChargesBySOId'
			,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@MasterCompanyId, '') AS varchar(100))  			                                           
			,@ApplicationName VARCHAR(100) = 'PAS'
		-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException @DatabaseName = @DatabaseName
			,@AdhocComments = @AdhocComments
			,@ProcedureParameters = @ProcedureParameters
			,@ApplicationName = @ApplicationName
			,@ErrorLogID = @ErrorLogID OUTPUT;

		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)

		RETURN (1);           
	END CATCH
END;
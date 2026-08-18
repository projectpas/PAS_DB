/*************************************************************
** File: [USP_GetPartDetailsWithIdForSinglePart]
** Author:   Ayushi Patel
** Description: Get Part Details With Id For Single Part
** Purpose:  
** Date:     03-07-2025
**************************************************************
** Change History
**************************************************************
** PR   Date         Author         Change Description
** --   ----------   ------------   --------------------------------
** 1    03-07-2025   Ayushi Patel   Created
	2    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
-- EXEC[USP_GetPartDetailsWithIdForSinglePart] 4797
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetPartDetailsWithIdForSinglePart]
    @PartId BIGINT,
    @ConditionId BIGINT = 0
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        SELECT 
            IM.PartNumber,
            IM.PartAlternatePartId,
            IM.PartDescription,
            IM.ManufacturerId,
            ISNULL(MF.Name, '') AS [Name],
            IM.ReorderQuantiy,
            IM.ItemTypeId,
            IM.ItemMasterId,
            IM.IsHazardousMaterial,
            IM.PriorityId,
            IM.GLAccountId,
            IM.PurchaseUnitOfMeasureId,
            ISNULL(UM.ShortName, '') AS ShortName,
            ISNULL(IM.IsPma,0)AS IsPma,
            ISNULL(IM.IsDER,0) AS IsDER,
            ps.PP_VendorListPrice AS vendorListPrice,
            ps.PP_PurchaseDiscPerc AS discountPercent,
            ps.PP_PurchaseDiscAmount AS discountPerUnit,
            ps.PP_UnitPurchasePrice AS unitCost,
            CASE 
                WHEN IM.IsPma = 1 AND IM.IsDER = 1 THEN 'PMA&DER'
                WHEN IM.IsPma = 1 AND ISNULL(IM.IsDER, 0) = 0 THEN 'PMA'
                WHEN ISNULL(IM.IsPma, 0) = 0 AND IM.IsDER = 1 THEN 'DER'
                ELSE 'OEM'
            END AS StockType,
            gl.AccountCode + '-' + gl.AccountName AS GLAccount,
            ps.ConditionId,
            IM.PurchaseUnitOfMeasure
        FROM dbo.ItemMaster IM WITH(NOLOCK)
        LEFT JOIN dbo.ItemMasterPurchaseSale ps WITH(NOLOCK) ON IM.ItemMasterId = ps.ItemMasterId
        LEFT JOIN dbo.Manufacturer MF WITH(NOLOCK) ON IM.ManufacturerId = MF.ManufacturerId
        LEFT JOIN dbo.UnitOfMeasure UM WITH(NOLOCK) ON IM.PurchaseUnitOfMeasureId = UM.UnitOfMeasureId
        INNER JOIN dbo.GLAccount gl WITH(NOLOCK) ON IM.GLAccountId = gl.GLAccountId
        WHERE IM.ItemMasterId = @PartId
        AND (@ConditionId = 0 OR ps.ConditionId = @ConditionId) AND ISNULL(IM.IsNonStock,0) = 0 ;
    END TRY
    BEGIN CATCH      
	         DECLARE @ErrorLogID INT
			,@DatabaseName VARCHAR(100) = db_name()
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			,@AdhocComments VARCHAR(150) = 'USP_GetPartDetailsWithIdForSinglePart'
			,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = '', '
			,@ApplicationName VARCHAR(100) = 'PAS'
		-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException @DatabaseName = @DatabaseName
			,@AdhocComments = @AdhocComments
			,@ProcedureParameters = @ProcedureParameters
			,@ApplicationName = @ApplicationName
			,@ErrorLogID = @ErrorLogID OUTPUT;

		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d',16,1,@ErrorLogID)
		RETURN (1);           
	END CATCH
END
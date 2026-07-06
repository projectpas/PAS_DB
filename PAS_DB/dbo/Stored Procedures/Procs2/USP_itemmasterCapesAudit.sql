/*************************************************************           
 ** File:		 [dbo].[USP_itemmasterCapesAudit]          
 ** Author:		 Nakul Chandigra
 ** Description: This Stored Procedure Is Used for getting history of ItemMasterCapes
 ** Purpose:         
 ** Date:   25-09-2025 
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date				Author				Change Description            
 ** --   -------------		----------------	--------------------------------          
	1	 26-09-2025			Nakul Chandigra		Created
	2    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
	EXEC [dbo].[USP_itemmasterCapesAudit] 8750 , 2
**************************************************************/
CREATE    PROCEDURE [dbo].[USP_itemmasterCapesAudit]
@itemMasterCapesId BIGINT,
@EmpId BIGINT
AS
BEGIN

	DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';
		SELECT @CurrntEmpTimeZoneDesc = COALESCE(ETZ.[Description], LTZ.[Description]) FROM dbo.Employee E WITH (NOLOCK) 
			LEFT JOIN dbo.TimeZone ETZ WITH (NOLOCK) ON E.TimeZoneId = ETZ.TimeZoneId
			LEFT JOIN dbo.LegalEntity LE WITH (NOLOCK) ON E.LegalEntityId = LE.LegalEntityId
			LEFT JOIN dbo.TimeZone LTZ WITH (NOLOCK) ON LE.TimeZoneId = LTZ.TimeZoneId
		WHERE E.EmployeeId = @EmpId; 
	declare @ItemMasterCapesMsModuleId BIGINT;

	SELECT @ItemMasterCapesMsModuleId = ManagementStructureModuleId
	FROM [dbo].ManagementStructureModule WITH (NOLOCK)
	WHERE ModuleName = 'ItemMasterCapes';
	BEGIN TRY
		SELECT		 (IMCA.AuditItemMasterCapesId) AS  AuditItemMasterCapesId
			  ,		 (IMCA.ItemMasterCapesId) AS ItemMasterCapesId
			  ,ISNULL(IMCA.PartNumber, '') AS partNo
			  ,ISNULL(IMCA.PartDescription, '' ) AS pnDiscription
			  ,ISNULL(IMCA.CapabilityType,'') AS capabilityType
			  ,		 (IMCA.IsVerified) AS isVerified
			  ,ISNULL(IMCA.VerifiedBy,'')AS verifiedBy
			  ,CASE WHEN CAST(IMCA.verifiedDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE)THEN NULL ELSE (Cast(DBO.ConvertUTCtoLocal(IMCA.verifiedDate, @CurrntEmpTimeZoneDesc) AS DATETIME))END verifiedDate
			  ,		 (IMCA.AddedDate )AS addedDate 
			  ,      (IMCA.Memo)AS memo
			  ,      (IMCA.IsActive)AS isActive
			  ,		 (IMCA.ManagementStructureId)AS ManagementStrId
			  ,		 (IMCA.UpdatedBy)AS UpdatedBy
			  ,CASE WHEN CAST(IMCA.UpdatedDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE)THEN NULL ELSE (Cast(DBO.ConvertUTCtoLocal(IMCA.UpdatedDate, @CurrntEmpTimeZoneDesc) AS DATETIME))END UpdatedDate
			  ,      (IMCA.CreatedBy)AS CreatedBy 
			  ,CASE WHEN CAST(IMCA.CreatedDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE)THEN NULL ELSE (Cast(DBO.ConvertUTCtoLocal(IMCA.CreatedDate, @CurrntEmpTimeZoneDesc) AS DATETIME))END createdDate
			  ,      (IMCA.isDeleted)AS isDeleted
			  ,ISNULL(msd.LastMSLevel,'')AS LastMSLevel
			  ,ISNULL(msd.AllMSlevels,'')AS AllMSlevels
			  ,      (IM.ManufacturerName)AS ManufacturerName
		FROM [dbo].[ItemMasterCapesAudit] IMCA WITH (NOLOCK)
		LEFT JOIN [dbo].[ItemMasterManagementStructureDetailsAudit] msd WITH (NOLOCK) ON IMCA.ItemMasterCapesId = msd.ReferenceID AND msd.ModuleID = @ItemMasterCapesMsModuleId
		LEFT JOIN [dbo].[ItemMaster] IM WITH (NOLOCK)	ON IMCA.ItemMasterId = IM.ItemMasterId
		 AND ISNULL(IM.IsNonStock,0) = 0 WHERE IMCA.ItemMasterCapesId = @ItemMasterCapesId AND IMCA.PartNumber IS NOT NULL
		ORDER BY IMCA.AuditItemMasterCapesId DESC 

	END TRY 
	BEGIN CATCH
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = '[dbo].[USP_itemmasterCapesAudit]'
			  , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = '''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException @DatabaseName = @DatabaseName
			,@AdhocComments = @AdhocComments
			,@ProcedureParameters = @ProcedureParameters
			,@ApplicationName = @ApplicationName
			,@ErrorLogID = @ErrorLogID OUTPUT;

		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)

		RETURN (1); 
	END CATCH

END
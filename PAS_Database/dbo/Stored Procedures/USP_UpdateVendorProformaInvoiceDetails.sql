/*************************************************************           
 ** File:   [USP_UpdateVendorProformaInvoiceDetails]           
 ** Author:  Rajesh Gami
 ** Description:  To Update the vendor proforma Details For Approval Process
 ** Purpose:         
 ** Date:        
          
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date			Author				Change Description            
 ** --   --------		-------			--------------------------------          
    1    30Dec2024		Rajesh Gami			Created

--exec [dbo].[USP_UpdateVendorProformaInvoiceDetails] 105
************************************************************************/
CREATE     Procedure [dbo].[USP_UpdateVendorProformaInvoiceDetails]
	@VendorProformaInvoiceId  BIGINT
AS
BEGIN

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON 
BEGIN TRY

		DECLARE @VendorId BIGINT;
		SET @VendorId = (SELECT VendorId FROM Dbo.VendorProformaInvoiceHeader WITH (NOLOCK) WHERE VendorProformaInvoiceId = @VendorProformaInvoiceId)

		UPDATE VPI SET
		VPI.StatusId = (SELECT VendorProformaInvoiceHeaderStatusId FROM dbo.VendorProformaInvoiceHeaderStatus Where IsActive = 1 and IsDeleted = 0  and [Description] = 'Approved' ),
		VPI.ApproverId = ISNULL((select TOP 1 PA.ApprovedById from dbo.VendorProformaInvoiceApproval PA WITH (NOLOCK) INNER JOIN
							dbo.ApprovalStatus APS WITH (NOLOCK) ON PA.StatusId = APS.ApprovalStatusId   AND APS.Name =  'Approved'
							WHERE VendorProformaInvoiceId = @VendorProformaInvoiceId ORDER BY ApprovedDate DESC),0),
		VPI.DateApproved = (select TOP 1 PA.ApprovedDate from dbo.VendorProformaInvoiceApproval PA WITH (NOLOCK)
							INNER JOIN
							dbo.ApprovalStatus APS WITH (NOLOCK) ON PA.StatusId = APS.ApprovalStatusId   AND APS.Name =  'Approved'
							WHERE VendorProformaInvoiceId = @VendorProformaInvoiceId ORDER BY ApprovedDate DESC)
		FROM dbo.VendorProformaInvoiceHeader VPI WITH (NOLOCK)
		WHERE VendorProformaInvoiceId = @VendorProformaInvoiceId
		AND 
		ISNULL((SELECT Count(PA.VendorProformaInvoiceApprovalId) 
				FROM dbo.VendorProformaInvoiceApproval PA WITH (NOLOCK) INNER JOIN dbo.ApprovalStatus APS WITH (NOLOCK)
					 ON PA.StatusId = APS.ApprovalStatusId   AND APS.Name =  'Approved'
					 INNER JOIN dbo.VendorProformaInvoicePartDetails POP WITH (NOLOCK) ON POP.VendorProformaInvoicePartDetailsId = PA.VendorProformaInvoicePartDetailsId
					 WHERE POP.VendorProformaInvoiceId = @VendorProformaInvoiceId),0) = ISNULL((select Count(VendorProformaInvoicePartDetailsId) from dbo.VendorProformaInvoicePartDetails WITH (NOLOCK)  WHERE  VendorProformaInvoiceId = @VendorProformaInvoiceId),0)
		AND 
			(SELECT Count(PA.VendorProformaInvoiceApprovalId) FROM 
			dbo.VendorProformaInvoiceApproval PA WITH (NOLOCK)
			INNER JOIN dbo.ApprovalStatus APS WITH (NOLOCK) ON PA.StatusId = APS.ApprovalStatusId  AND APS.Name =  'Approved'
			INNER JOIN dbo.VendorProformaInvoicePartDetails POP WITH (NOLOCK) ON POP.VendorProformaInvoicePartDetailsId = PA.VendorProformaInvoicePartDetailsId
			WHERE POP.VendorProformaInvoiceId = @VendorProformaInvoiceId) > 0
		AND
			(SELECT COUNT(POA.VendorShippingAddressId)  FROM  dbo.VendorShippingAddress POA WITH (NOLOCK)  
			WHERE POA.VendorId = @VendorId AND POA.IsPrimary = 1)  > 0
		AND
			(SELECT COUNT(POA.VendorBillingAddressId)  FROM  dbo.VendorBillingAddress POA  WITH (NOLOCK)
			WHERE POA.VendorId = @VendorId AND POA.IsPrimary = 1)  > 0

		UPDATE dbo.VendorProformaInvoiceApproval SET ApprovedById = null , ApprovedDate = null , ApprovedByName = null
		Where VendorProformaInvoiceId = @VendorProformaInvoiceId and StatusId != (select ApprovalStatusId from  dbo.ApprovalStatus WITH (NOLOCK) WHERE Name  =  'Approved') 


		UPDATE dbo.VendorProformaInvoiceApproval SET RejectedBy = null , RejectedDate =  null , RejectedByName = null
		Where VendorProformaInvoiceId = @VendorProformaInvoiceId and StatusId != (select ApprovalStatusId from  dbo.ApprovalStatus WITH (NOLOCK) WHERE Name  =  'Rejected') 

		UPDATE dbo.VendorProformaInvoiceApproval
		SET ApprovedByName = AE.FirstName + ' ' + AE.LastName,
			RejectedByName = RE.FirstName + ' ' + RE.LastName,
			StatusName = ASS.Description,
			InternalSentToName = (INST.FirstName + ' ' + INST.LastName)
		FROM dbo.VendorProformaInvoiceApproval PA
			 LEFT JOIN dbo.Employee AE on PA.ApprovedById = AE.EmployeeId
			 LEFT JOIN DBO.Employee INST WITH (NOLOCK) ON INST.EmployeeId = PA.InternalSentToId
			 LEFT JOIN dbo.Employee RE on PA.RejectedBy = RE.EmployeeId
			 LEFT JOIN dbo.ApprovalStatus ASS on PA.StatusId = ASS.ApprovalStatusId

		UPDATE VPI
		SET VPI.ApprovedBy = ISNULL(AP.FirstName,'') + ' ' + ISNULL(AP.LastName,'')
		FROM dbo.VendorProformaInvoiceHeader VPI WITH (NOLOCK)
		LEFT JOIN dbo.Employee AP WITH (NOLOCK) ON VPI.ApproverId = AP.EmployeeId
		WHERE VPI.VendorProformaInvoiceId = @VendorProformaInvoiceId

END TRY	
BEGIN CATCH

IF OBJECT_ID(N'tempdb..#ARMSID') IS NOT NULL
BEGIN
DROP TABLE #ARMSID 
END

	DECLARE @ErrorLogID INT
	,@DatabaseName VARCHAR(100) = db_name()
	-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
	,@AdhocComments VARCHAR(150) = 'USP_UpdateVendorProformaInvoiceDetails'
	, @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ CAST(ISNULL(@VendorProformaInvoiceId, '') as Varchar(100)) 
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

	IF OBJECT_ID(N'tempdb..#ARMSID') IS NOT NULL
	BEGIN
		DROP TABLE #ARMSID 
	END
END
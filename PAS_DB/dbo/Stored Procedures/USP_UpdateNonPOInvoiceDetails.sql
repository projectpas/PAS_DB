/*************************************************************           
 ** File:   [USP_UpdateNonPOInvoiceDetails]           
 ** Author:  Devendra Shekh
 ** Description:  To Update the Non PO Details For Approval Process
 ** Purpose:         
 ** Date:        
          
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author				Change Description            
 ** --   --------     -------			--------------------------------          
    1    06/08/2023  Devendra Shekh			Created
    1    02/10/2023  Devendra Shekh			Updating npoHeader for approvedby
     
--exec [dbo].[USP_UpdateNonPOInvoiceDetails] 9, 
************************************************************************/
CREATE   Procedure [dbo].[USP_UpdateNonPOInvoiceDetails]
	@NonPOInvoiceId  BIGINT
AS
BEGIN

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON 
BEGIN TRY

		DECLARE @VendorId BIGINT;
		SET @VendorId = (SELECT VendorId FROM NonPOInvoiceHeader WHERE NonPOInvoiceId = @NonPOInvoiceId)

		UPDATE NPO SET
		NPO.StatusId = (SELECT NonPOInvoiceHeaderStatusId FROM dbo.NonPOInvoiceHeaderStatus Where IsActive = 1 and IsDeleted = 0  and [Description] = 'Fulfilling' ),
		NPO.ApproverId = ISNULL((select TOP 1 PA.ApprovedById from dbo.NonPOApproval PA WITH (NOLOCK) INNER JOIN
							dbo.ApprovalStatus APS WITH (NOLOCK) ON PA.StatusId = APS.ApprovalStatusId   AND APS.Name =  'Approved'
							WHERE NonPOInvoiceId = @NonPOInvoiceId ORDER BY ApprovedDate DESC),0),
		NPO.DateApproved = (select TOP 1 PA.ApprovedDate from dbo.NonPOApproval PA WITH (NOLOCK)
							INNER JOIN
							dbo.ApprovalStatus APS WITH (NOLOCK) ON PA.StatusId = APS.ApprovalStatusId   AND APS.Name =  'Approved'
							WHERE NonPOInvoiceId = @NonPOInvoiceId ORDER BY ApprovedDate DESC)
		FROM dbo.NonPOInvoiceHeader NPO WITH (NOLOCK)
		WHERE NonPOInvoiceId = @NonPOInvoiceId
		AND 
		ISNULL((SELECT Count(PA.NonPOApprovalId) 
				FROM dbo.NonPOApproval PA WITH (NOLOCK) INNER JOIN dbo.ApprovalStatus APS WITH (NOLOCK)
					 ON PA.StatusId = APS.ApprovalStatusId   AND APS.Name =  'Approved'
					 INNER JOIN dbo.NonPOInvoicePartDetails POP WITH (NOLOCK) ON POP.NonPOInvoicePartDetailsId = PA.NonPOInvoicePartDetailsId
					 WHERE POP.NonPOInvoiceId = @NonPOInvoiceId),0) = ISNULL((select Count(NonPOInvoicePartDetailsId) from dbo.NonPOInvoicePartDetails  WHERE  NonPOInvoiceId = @NonPOInvoiceId),0)
		AND 
			(SELECT Count(PA.NonPOApprovalId) FROM 
			dbo.NonPOApproval PA WITH (NOLOCK)
			INNER JOIN dbo.ApprovalStatus APS WITH (NOLOCK) ON PA.StatusId = APS.ApprovalStatusId  AND APS.Name =  'Approved'
			INNER JOIN dbo.NonPOInvoicePartDetails POP WITH (NOLOCK) ON POP.NonPOInvoicePartDetailsId = PA.NonPOInvoicePartDetailsId
			WHERE POP.NonPOInvoiceId = @NonPOInvoiceId) > 0
		AND
			(SELECT COUNT(POA.VendorShippingAddressId)  FROM  dbo.VendorShippingAddress POA WITH (NOLOCK)  
			WHERE POA.VendorId = @VendorId AND POA.IsPrimary = 1)  > 0
		AND
			(SELECT COUNT(POA.VendorBillingAddressId)  FROM  dbo.VendorBillingAddress POA  WITH (NOLOCK)
			WHERE POA.VendorId = @VendorId AND POA.IsPrimary = 1)  > 0

		UPDATE dbo.NonPOApproval SET ApprovedById = null , ApprovedDate = null , ApprovedByName = null
		Where NonPOInvoiceId = @NonPOInvoiceId and StatusId != (select ApprovalStatusId from  dbo.ApprovalStatus WHERE Name  =  'Approved') 


		UPDATE dbo.NonPOApproval SET RejectedBy = null , RejectedDate =  null , RejectedByName = null
		Where NonPOInvoiceId = @NonPOInvoiceId and StatusId != (select ApprovalStatusId from  dbo.ApprovalStatus WHERE Name  =  'Rejected') 

		UPDATE dbo.NonPOApproval
		SET ApprovedByName = AE.FirstName + ' ' + AE.LastName,
			RejectedByName = RE.FirstName + ' ' + RE.LastName,
			StatusName = ASS.Description,
			InternalSentToName = (INST.FirstName + ' ' + INST.LastName)
		FROM dbo.NonPOApproval PA
			 LEFT JOIN dbo.Employee AE on PA.ApprovedById = AE.EmployeeId
			 LEFT JOIN DBO.Employee INST WITH (NOLOCK) ON INST.EmployeeId = PA.InternalSentToId
			 LEFT JOIN dbo.Employee RE on PA.RejectedBy = RE.EmployeeId
			 LEFT JOIN dbo.ApprovalStatus ASS on PA.StatusId = ASS.ApprovalStatusId

		UPDATE NPO
		SET NPO.ApprovedBy = ISNULL(AP.FirstName,'') + ' ' + ISNULL(AP.LastName,'')
		FROM dbo.NonPOInvoiceHeader NPO WITH (NOLOCK)
		LEFT JOIN dbo.Employee AP WITH (NOLOCK) ON NPO.ApproverId = AP.EmployeeId
		WHERE NPO.NonPOInvoiceId = @NonPOInvoiceId

END TRY	
BEGIN CATCH

IF OBJECT_ID(N'tempdb..#ARMSID') IS NOT NULL
BEGIN
DROP TABLE #ARMSID 
END

	DECLARE @ErrorLogID INT
	,@DatabaseName VARCHAR(100) = db_name()
	-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
	,@AdhocComments VARCHAR(150) = 'USP_UpdateNonPOInvoiceDetails'
	, @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ CAST(ISNULL(@NonPOInvoiceId, '') as Varchar(100)) 
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
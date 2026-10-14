/*************************************************************
 ** File:   [udfGetIntegrationEmailRfqStatus]
 ** Author:  Bhargav Saliya
 ** Description: Single place that decides the RFQ processing status shown on the Email List and whether the
 **              email may be edited / re-synced. Use with CROSS APPLY.
 ** Purpose:     RFQ Email List - Error Message / Edit / Re-Sync
 ** Date:   12 Oct 2026
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date			Author				Change Description
 ** --   --------		-------				--------------------------------
    1    12 Oct 2026	Bhargav Saliya		Created

 -- Status ids (EmailStatusEnum): 1 = Pending, 2 = InProgress, 3 = Completed, 4 = Failed
 -- Processed (read-only) = RFQ already created from this email (CustomerRfq / ThirdPartyRFQ / VendorRFQPart) or Completed.
 -- Editable = Failed, Pending, Not Processed or an abandoned (>30 min) InProgress, and not in Trash (EmailSection 4).
************************************************************************/
CREATE   FUNCTION [dbo].[udfGetIntegrationEmailRfqStatus]
(
	@IntegrationEmailID BIGINT,
	@EmailStatusId INT,
	@CustomerRfqId BIGINT,
	@ThirdPartyRFQId BIGINT,
	@EmailSection INT,
	@LastProcessedDate DATETIME2(7)
)
RETURNS TABLE
AS
RETURN
(
	SELECT S.[IsRfqCreated],
		   CASE WHEN S.[IsRfqCreated] = 1 OR ISNULL(@EmailStatusId, 0) = 3 THEN 'Processed'
				WHEN ISNULL(@EmailStatusId, 0) = 4 THEN 'Failed'
				WHEN ISNULL(@EmailStatusId, 0) = 2 THEN 'In Progress'
				WHEN ISNULL(@EmailStatusId, 0) = 1 THEN 'Pending'
				ELSE 'Not Processed' END AS [EmailStatusName],
		   CAST(CASE WHEN S.[IsRfqCreated] = 1 OR ISNULL(@EmailStatusId, 0) = 3 OR ISNULL(@EmailSection, 0) = 4 THEN 0
					 -- InProgress is locked, unless the claim is abandoned (same 30 min rule as usp_ClaimIntegrationEmailForProcessing)
					 WHEN ISNULL(@EmailStatusId, 0) = 2 AND ISNULL(@LastProcessedDate, GETUTCDATE()) >= DATEADD(MINUTE, -30, GETUTCDATE()) THEN 0
					 ELSE 1 END AS BIT) AS [IsEditable]
	FROM (
		SELECT CAST(CASE WHEN ISNULL(@CustomerRfqId, 0) > 0
						   OR ISNULL(@ThirdPartyRFQId, 0) > 0
						   OR EXISTS(SELECT 1 FROM [dbo].[VendorRFQPart] VRP WITH(NOLOCK) WHERE VRP.[IntegrationEmailID] = @IntegrationEmailID)
						 THEN 1 ELSE 0 END AS BIT) AS [IsRfqCreated]
	) S
);

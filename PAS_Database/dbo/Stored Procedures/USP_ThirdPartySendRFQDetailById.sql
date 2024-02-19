
/*************************************************************           
 ** File:   [USP_ThirdPartySendRFQDetailById]           
 ** Author: Rajesh Gami
 ** Description: This stored procedure is used to Third Party Send RFQ Detail By Id
 ** Date:   16/02/2024
 ** PARAMETERS:           
 ** RETURN VALUE:
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author  		Change Description            
 ** --   --------     -------		---------------------------     
    1    16/02/2024   Rajesh Gami     Created
**************************************************************
 EXEC USP_ThirdPartySendRFQDetailById 1,1 
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_ThirdPartySendRFQDetailById] 
@ILSRFQPartId bigint =0,
@MasterCompanyId int = 0
AS
BEGIN
  SET NOCOUNT ON;
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  BEGIN TRY
  BEGIN TRANSACTION
	BEGIN
		
		IF (@ILSRFQPartId >0)
		BEGIN
		   	  SELECT DISTINCT
					   part.ILSRFQPartId ILSRFQPartId,
					   tr.ThirdPartyRFQId,
					   ird.ILSRFQDetailId,
					   tr.RFQId,
					   tr.PortalRFQId,
					   tr.[Name] AS Name,
					   tr.IntegrationRFQTypeId IntegrationRFQTypeId,
					   tr.TypeName,
					   tr.IntegrationPortalId IntegrationPortalId,
					   tr.IntegrationPortal,
					   tr.IntegrationRFQStatusId IntegrationRFQStatusId,
					   tr.Status Status,
					   ISNULL(ird.PriorityId,0) PriorityId,
					   ird.Priority,
					   ISNULL(ird.RequestedQty,0) RequestedQty,
					   ird.QuoteWithinDays QuoteWithinDays,
					   ird.DeliverByDate DeliverByDate,
					   ird.PreparedBy,
					   ISNULL(ird.AttachmentId,0) AttachmentId,
					   ird.DeliverToAddress,
					   ird.BuyerComment,					   
					   part.PartNumber,
					   part.AltPartNumber,
					   part.Exchange,
					   part.Description,
					   ISNULL(part.Qty,0) Qty,
					   part.Condition,
					   ISNULL(part.IsEmail,0) IsEmail,
					   ISNULL(part.IsFax,0) IsFax,
                       ISNULL(part.IsActive,0) IsActive,
                       ISNULL(part.IsDeleted,0) IsDeleted,
					   part.CreatedDate,
                       part.UpdatedDate,
					   Upper(part.CreatedBy) CreatedBy,
                       Upper(part.UpdatedBy) UpdatedBy,
					   part.MasterCompanyId
			    FROM Dbo.ILSRFQPart part WITH(NOLOCK)
					INNER JOIN Dbo.ILSRFQDetail ird WITH(NOLOCK) on part.ILSRFQDetailId = ird.ILSRFQDetailId
					INNER JOIN Dbo.ThirdPartyRFQ tr WITH(NOLOCK)  on ird.ThirdPartyRFQId = tr.ThirdPartyRFQId
			    WHERE part.ILSRFQPartId = @ILSRFQPartId AND part.MasterCompanyId = @MasterCompanyId
		END
		
	END
	COMMIT  TRANSACTION
  END TRY
  BEGIN CATCH
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
		DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME()
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            ,@AdhocComments varchar(150) = '[USP_ThirdPartySendRFQDetailById]',
            @ProcedureParameters varchar(3000) = '@ILSRFQPartId = ''' + CAST(ISNULL(@ILSRFQPartId, '') AS varchar(100)),
            @ApplicationName varchar(100) = 'PAS'
    -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
    EXEC spLogException @DatabaseName = @DatabaseName,
                        @AdhocComments = @AdhocComments,
                        @ProcedureParameters = @ProcedureParameters,
                        @ApplicationName = @ApplicationName,
                        @ErrorLogID = @ErrorLogID OUTPUT;
    RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
    RETURN (1);
  END CATCH
END
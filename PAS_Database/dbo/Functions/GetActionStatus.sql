CREATE FUNCTION [dbo].[GetActionStatus]
(
    @ApprovalActionId INT = NULL,
    @IsInternalApprove BIT,
    @IsApprovalRule BIT
)
RETURNS NVARCHAR(200)
AS
BEGIN
    DECLARE @Result NVARCHAR(200);
    DECLARE @FinalActionId INT;
	DECLARE	@SentForInternalApproval INT = 1
    DECLARE @SubmitInternalApproval  INT = 2
    DECLARE @SentForCustomerApproval INT = 3
    DECLARE @SubmitCustomerApproval  INT = 4
    DECLARE @Approved INT = 5
	    
    SET @FinalActionId = dbo.GetApprovalActionId(@ApprovalActionId, @IsInternalApprove, @IsApprovalRule);

    IF @FinalActionId = @Approved -- Approved
        SET @Result = 'Approved';
    ELSE IF @FinalActionId = @SubmitCustomerApproval -- SubmitCustomerApproval
        SET @Result = 'Submitted for Cust Approval';
    ELSE IF @FinalActionId = @SentForCustomerApproval -- SentForCustomerApproval
        SET @Result = 'Send for Customer Approval';
    ELSE IF @FinalActionId = @SubmitInternalApproval -- SubmitInternalApproval
        SET @Result = 'Submitted for Internal Approval';
    ELSE IF @FinalActionId = @SentForInternalApproval -- SentForInternalApproval
        SET @Result = 'Send for Internal Approval';
    ELSE
        SET @Result = '';

    RETURN @Result;
END
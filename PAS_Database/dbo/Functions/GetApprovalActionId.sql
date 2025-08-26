CREATE FUNCTION [dbo].[GetApprovalActionId]
(
    @ApprovalActionId INT = NULL,
    @IsInternalApprove BIT,
    @IsApprovalRule BIT   
)
RETURNS INT
AS
BEGIN
    DECLARE @Result INT;
	DECLARE @SentForCustomerApproval INT = 3,@SentForInternalApproval INT = 1
    
    IF ISNULL(@ApprovalActionId, 0) = 0
    BEGIN        
        IF @IsApprovalRule = 0
        BEGIN
            SET @Result = @SentForCustomerApproval -- SentForCustomerApproval enum
        END
        ELSE
        BEGIN
            IF @IsInternalApprove = 1
                SET @Result = @SentForInternalApproval;            -- SentForInternalApproval
            ELSE
                SET @Result = @SentForCustomerApproval;    -- SentForCustomerApproval
        END
    END
    ELSE
    BEGIN
        SET @Result = @ApprovalActionId;
    END

    RETURN @Result;
END
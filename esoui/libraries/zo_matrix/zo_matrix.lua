hstructure Matrix33
    _11 : number
    _12 : number
    _13 : number
    _21 : number
    _22 : number
    _23 : number
    _31 : number
    _32 : number
    _33 : number
end

function zo_setToIdentityMatrix33(m : Matrix33)
    m._11 = 1
    m._12 = 0
    m._13 = 0
    m._21 = 0
    m._22 = 1
    m._23 = 0
    m._31 = 0
    m._32 = 0
    m._33 = 1
end

function zo_setToRotationMatrix2D(m : Matrix33, radians)
    local cosResult = math.cos(radians)
    local sinResult = math.sin(radians)

    m._11 = cosResult
    m._12 = sinResult
    m._13 = 0
    m._21 = -sinResult
    m._22 = cosResult
    m._23 = 0
    m._31 = 0
    m._32 = 0
    m._33 = 1
end

function zo_setToTranslationMatrix2D(m : Matrix33, x, y)
    m._11 = 1
    m._12 = 0
    m._13 = x
    m._21 = 0
    m._22 = 1
    m._23 = -y
    m._31 = 0
    m._32 = 0
    m._33 = 1
end

function zo_setToScaleMatrix2D(m : Matrix33, scale)
    m._11 = scale
    m._12 = 0
    m._13 = 0
    m._21 = 0
    m._22 = scale
    m._23 = 0
    m._31 = 0
    m._32 = 0
    m._33 = 1
end

function zo_invertMatrix33(m : Matrix33, result : Matrix33)
    local determinant = m._11 * (m._22 * m._33 - m._32 * m._23) -
                        m._12 * (m._21 * m._33 - m._23 * m._31) +
                        m._13 * (m._21 * m._32 - m._22 * m._31)
    local inverseDeterminant = 1 / determinant

    -- store values in locals so we can reuse m as our result matrix
    local _11 = (m._22 * m._33 - m._32 * m._23) * inverseDeterminant
    local _12 = (m._13 * m._32 - m._12 * m._33) * inverseDeterminant
    local _13 = (m._12 * m._23 - m._13 * m._22) * inverseDeterminant
    local _21 = (m._23 * m._31 - m._21 * m._33) * inverseDeterminant
    local _22 = (m._11 * m._33 - m._13 * m._31) * inverseDeterminant
    local _23 = (m._21 * m._13 - m._11 * m._23) * inverseDeterminant
    local _31 = (m._21 * m._32 - m._31 * m._22) * inverseDeterminant
    local _32 = (m._31 * m._12 - m._11 * m._32) * inverseDeterminant
    local _33 = (m._11 * m._22 - m._21 * m._12) * inverseDeterminant

    result._11 = _11
    result._12 = _12
    result._13 = _13
    result._21 = _21
    result._22 = _22
    result._23 = _23
    result._31 = _31
    result._32 = _32
    result._33 = _33
    --[[
        XXX REVIEW XXX
        I have never taken a linear algebra course :( this is just a straight copy-paste from 
        https://stackoverflow.com/questions/983999/simple-3x3-matrix-inverse-code-c
        namely, this answer:
        // computes the inverse of a matrix m
        double det = m(0, 0) * (m(1, 1) * m(2, 2) - m(2, 1) * m(1, 2)) -
                     m(0, 1) * (m(1, 0) * m(2, 2) - m(1, 2) * m(2, 0)) +
                     m(0, 2) * (m(1, 0) * m(2, 1) - m(1, 1) * m(2, 0));

        double invdet = 1 / det;

        Matrix33d minv; // inverse of matrix m
        minv(0, 0) = (m(1, 1) * m(2, 2) - m(2, 1) * m(1, 2)) * invdet;
        minv(0, 1) = (m(0, 2) * m(2, 1) - m(0, 1) * m(2, 2)) * invdet;
        minv(0, 2) = (m(0, 1) * m(1, 2) - m(0, 2) * m(1, 1)) * invdet;
        minv(1, 0) = (m(1, 2) * m(2, 0) - m(1, 0) * m(2, 2)) * invdet;
        minv(1, 1) = (m(0, 0) * m(2, 2) - m(0, 2) * m(2, 0)) * invdet;
        minv(1, 2) = (m(1, 0) * m(0, 2) - m(0, 0) * m(1, 2)) * invdet;
        minv(2, 0) = (m(1, 0) * m(2, 1) - m(2, 0) * m(1, 1)) * invdet;
        minv(2, 1) = (m(2, 0) * m(0, 1) - m(0, 0) * m(2, 1)) * invdet;
        minv(2, 2) = (m(0, 0) * m(1, 1) - m(1, 0) * m(0, 1)) * invdet;

        because we're doing index by one here's a version that find-replaces all the numbers to be +1

        // computes the inverse of a matrix m
        double det = m(1, 1) * (m(2, 2) * m(3, 3) - m(3, 2) * m(2, 3)) -
                     m(1, 2) * (m(2, 1) * m(3, 3) - m(2, 3) * m(3, 1)) +
                     m(1, 3) * (m(2, 1) * m(3, 2) - m(2, 2) * m(3, 1));

        double invdet = 2 / det;

        Matrix33d minv; // inverse of matrix m
        minv(1, 1) = (m(2, 2) * m(3, 3) - m(3, 2) * m(2, 3)) * invdet;
        minv(1, 2) = (m(1, 3) * m(3, 2) - m(1, 2) * m(3, 3)) * invdet;
        minv(1, 3) = (m(1, 2) * m(2, 3) - m(1, 3) * m(2, 2)) * invdet;
        minv(2, 1) = (m(2, 3) * m(3, 1) - m(2, 1) * m(3, 3)) * invdet;
        minv(2, 2) = (m(1, 1) * m(3, 3) - m(1, 3) * m(3, 1)) * invdet;
        minv(2, 3) = (m(2, 1) * m(1, 3) - m(1, 1) * m(2, 3)) * invdet;
        minv(3, 1) = (m(2, 1) * m(3, 2) - m(3, 1) * m(2, 2)) * invdet;
        minv(3, 2) = (m(3, 1) * m(1, 2) - m(1, 1) * m(3, 2)) * invdet;
        minv(3, 3) = (m(1, 1) * m(2, 2) - m(2, 1) * m(1, 2)) * invdet;
    ]]--
end

function zo_matrixMultiply33x33(a : Matrix33, b : Matrix33, result : Matrix33)
    -- store values in locals so we can reuse a or b as our result matrix
    local _11 = a._11 * b._11 + a._12 * b._21 + a._13 * b._31
    local _12 = a._11 * b._12 + a._12 * b._22 + a._13 * b._32
    local _13 = a._11 * b._13 + a._12 * b._23 + a._13 * b._33
    local _21 = a._21 * b._11 + a._22 * b._21 + a._23 * b._31
    local _22 = a._21 * b._12 + a._22 * b._22 + a._23 * b._32
    local _23 = a._21 * b._13 + a._22 * b._23 + a._23 * b._33
    local _31 = a._31 * b._11 + a._32 * b._21 + a._33 * b._31
    local _32 = a._31 * b._12 + a._32 * b._22 + a._33 * b._32
    local _33 = a._31 * b._13 + a._32 * b._23 + a._33 * b._33

    result._11 = _11
    result._12 = _12
    result._13 = _13
    result._21 = _21
    result._22 = _22
    result._23 = _23
    result._31 = _31
    result._32 = _32
    result._33 = _33
end

function zo_matrixTransformPoint(m : Matrix33, pointX, pointY)
    local outX = m._11 * pointX + m._12 * pointY + m._13
    local outY = m._21 * pointX + m._22 * pointY + m._23
    return outX, outY
end